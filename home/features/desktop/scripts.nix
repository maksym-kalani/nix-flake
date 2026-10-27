{ pkgs, config, ... }:
let
  toggle-audio = pkgs.writeShellScriptBin "toggle-audio" ''
    mapfile -t sinks < <(${pkgs.pulseaudio}/bin/pactl list short sinks | ${pkgs.gawk}/bin/awk '{print $2}')
    [ "''${#sinks[@]}" -gt 1 ] || exit 0
    current=$(${pkgs.pulseaudio}/bin/pactl info | ${pkgs.gawk}/bin/awk -F': ' '/Default Sink/ {print $2}')
    idx=-1
    for i in "''${!sinks[@]}"; do
      [[ "''${sinks[i]}" == "$current" ]] && { idx=$i; break; }
    done
    next=$(( (idx + 1) % ''${#sinks[@]} ))
    new_sink="''${sinks[next]}"
    ${pkgs.pulseaudio}/bin/pactl set-default-sink "$new_sink"
    ${pkgs.pulseaudio}/bin/pactl list short sink-inputs | ${pkgs.gawk}/bin/awk '{print $1}' | xargs -r -n1 ${pkgs.pulseaudio}/bin/pactl move-sink-input "$new_sink"
    desc=$(${pkgs.pulseaudio}/bin/pactl list sinks | grep -A20 "Name: $new_sink" | ${pkgs.gawk}/bin/awk -F': ' '/Description:/ {print $2; exit}')
    ${pkgs.libnotify}/bin/notify-send "🔈 Audio switched" "$desc"
  '';

  toggle-mute = pkgs.writeShellScriptBin "toggle-mute" ''
    default_src=$(${pkgs.pulseaudio}/bin/pactl get-default-source)
    ${pkgs.pulseaudio}/bin/pactl set-source-mute "$default_src" toggle
    state=$(${pkgs.pulseaudio}/bin/pactl get-source-mute @DEFAULT_SOURCE@ | ${pkgs.gawk}/bin/awk '{print $2}')
    if [ "$state" = "yes" ]; then
      ${pkgs.libnotify}/bin/notify-send "🎤 Mic muted"
    else
      ${pkgs.libnotify}/bin/notify-send "🎤 Mic unmuted"
    fi
  '';

  toggle-mute-zen = pkgs.writeShellScriptBin "toggle-mute-zen" ''
    zen_id=$(${pkgs.pulseaudio}/bin/pactl list sink-inputs \
      | ${pkgs.gawk}/bin/awk '
          /^Sink Input #[0-9]+/ { id = $3 }
          /application\.name = "Zen"/ { sub(/^#/,"",id); print id }
        ')
    if [[ -z "$zen_id" ]]; then
      ${pkgs.libnotify}/bin/notify-send "❌ Zen audio input not found."
      exit 1
    fi
    ${pkgs.pulseaudio}/bin/pactl set-sink-input-mute "$zen_id" toggle \
      && ${pkgs.libnotify}/bin/notify-send "🔊 Toggled mute on Zen" \
      || ${pkgs.libnotify}/bin/notify-send "⚠️ Failed to toggle mute"
  '';

  inc-volume-zen = pkgs.writeShellScriptBin "inc-volume-zen" ''
    zen_id=$(${pkgs.pulseaudio}/bin/pactl list sink-inputs \
      | ${pkgs.gawk}/bin/awk '
          /^Sink Input #[0-9]+/ { id = $3 }
          /application\.name = "Zen"/ { sub(/^#/,"",id); print id }
        ')
    if [[ -z "$zen_id" ]]; then
      ${pkgs.libnotify}/bin/notify-send "❌ Zen audio input not found."
      exit 1
    fi
    ${pkgs.pulseaudio}/bin/pactl set-sink-input-volume "$zen_id" +5%
  '';

  dec-volume-zen = pkgs.writeShellScriptBin "dec-volume-zen" ''
    zen_id=$(${pkgs.pulseaudio}/bin/pactl list sink-inputs \
      | ${pkgs.gawk}/bin/awk '
          /^Sink Input #[0-9]+/ { id = $3 }
          /application\.name = "Zen"/ { sub(/^#/,"",id); print id }
        ')
    if [[ -z "$zen_id" ]]; then
      ${pkgs.libnotify}/bin/notify-send "❌ Zen audio input not found."
      exit 1
    fi
    ${pkgs.pulseaudio}/bin/pactl set-sink-input-volume "$zen_id" -5%
  '';

  toggle-tv = pkgs.writeShellScriptBin "toggle-tv" ''
    set -euo pipefail

    MON="HDMI-A-1"
    MODE="3840x2160@60"
    POSITION="-3840x0"
    SCALE=1
    USB_SINK="alsa_output.usb-Solid_State_Logic_SSL_2_Mk_II-00.pro-output-0"
    HDMI_SINK="alsa_output.pci-0000_0d_00.1.pro-output-9"

    sink_exists() {
      ${pkgs.pulseaudio}/bin/pactl list short sinks | ${pkgs.gawk}/bin/awk '{print $2}' | grep -Fxq "$1"
    }

    switch_sink() {
      local target="$1"
      if ! sink_exists "$target"; then
        ${pkgs.libnotify}/bin/notify-send "🔈 Audio sink not found" "$target"
        return 1
      fi
      ${pkgs.pulseaudio}/bin/pactl set-default-sink "$target"
      sleep 0.15
      ${pkgs.pulseaudio}/bin/pactl list short sink-inputs | ${pkgs.gawk}/bin/awk '{print $1}' | while read -r id; do
        [[ -n "$id" ]] && ${pkgs.pulseaudio}/bin/pactl move-sink-input "$id" "$target"
      done
    }

    enable_tv() {
      hyprctl eval "hl.monitor({ output = \"$MON\", mode = \"$MODE\", position = \"$POSITION\", scale = $SCALE, disabled = false })" >/dev/null
      for _ in {1..40}; do
        sink_exists "$HDMI_SINK" && break
        sleep 0.25
      done
      switch_sink "$HDMI_SINK" || true
      swaybg -o "$MON" -i "${config.stylix.image}" -m fill &>/dev/null &
      ${pkgs.libnotify}/bin/notify-send "🖥️ TV ON" "$MON enabled; audio → HDMI"
    }

    disable_tv() {
      hyprctl eval "hl.monitor({ output = \"$MON\", disabled = true })" >/dev/null
      switch_sink "$USB_SINK" || true
      ${pkgs.libnotify}/bin/notify-send "🖥️ TV OFF" "$MON disabled; audio → USB DAC"
    }

    mon_json="$(hyprctl -j monitors 2>/dev/null || echo '[]')"
    mon_entry="$(${pkgs.jq}/bin/jq -r --arg n "$MON" '.[] | select(.name==$n)' <<<"$mon_json" || true)"

    tv_on=false
    if [[ -n "''${mon_entry}" ]]; then
      disabled="$(${pkgs.jq}/bin/jq -r '.disabled // false' <<<"$mon_entry")"
      [[ "$disabled" == "false" ]] && tv_on=true
    fi

    if [[ "$tv_on" == true ]]; then
      disable_tv
    else
      enable_tv
    fi
  '';

  prepare-game = pkgs.writeShellScriptBin "prepare-game" ''
    hyprctl dispatch workspace number 1
    vesktop &
    zen-browser --new-instance https://kavita.laufin.xyz/home &
    sleep 0.5
    hyprctl dispatch workspace number 8
    zen-browser --new-instance https://www.owlbear.rodeo/profile &
    sleep 0.5
    hyprctl dispatch workspace number 1
  '';

  hermes-browser = pkgs.writeShellScriptBin "hermes-browser" ''
    # Reverse-tunnels this Chromium's CDP port to Hermes so it can drive it while logins stay local.
    set -euo pipefail

    PORT="''${HERMES_BROWSER_PORT:-9222}"
    USER_DATA_DIR="''${HERMES_BROWSER_PROFILE:-$HOME/.local/share/chromium-hermes}"
    HERMES_HOST="''${HERMES_BROWSER_HOST:-maksym@192.168.2.205}"
    START_URL="''${1:-about:blank}"

    CHROME_PID=""
    cleanup() {
      if [[ -n "$CHROME_PID" ]] && kill -0 "$CHROME_PID" 2>/dev/null; then
        kill "$CHROME_PID" 2>/dev/null || true
      fi
    }
    trap cleanup EXIT INT TERM

    if ${pkgs.curl}/bin/curl -s --max-time 1 "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
      ${pkgs.libnotify}/bin/notify-send "🌐 Hermes browser" "Chromium already running on :$PORT — reusing it."
    else
      ${pkgs.chromium}/bin/chromium \
        --user-data-dir="$USER_DATA_DIR" \
        --remote-debugging-port="$PORT" \
        --remote-debugging-address=127.0.0.1 \
        --no-first-run \
        --no-default-browser-check \
        "$START_URL" &
      CHROME_PID=$!

      for _ in $(seq 1 50); do
        ${pkgs.curl}/bin/curl -s --max-time 1 "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1 && break
        sleep 0.2
      done
      ${pkgs.libnotify}/bin/notify-send "🌐 Hermes browser" "Chromium up on :$PORT, opening tunnel to $HERMES_HOST…"
    fi

    # Blocks here; Ctrl+C tears down the tunnel (and the Chromium we started).
    ${pkgs.openssh}/bin/ssh -N \
      -o ExitOnForwardFailure=yes \
      -o ServerAliveInterval=30 \
      -o ServerAliveCountMax=3 \
      -R 127.0.0.1:"$PORT":127.0.0.1:"$PORT" \
      "$HERMES_HOST"
  '';
in
{
  xdg.desktopEntries.hermes-browser = {
    name = "Hermes Browser";
    genericName = "Remote Browser";
    comment = "Start Chromium and its SSH tunnel to Hermes";
    exec = "${pkgs.kitty}/bin/kitty --title \"Hermes Browser\" ${hermes-browser}/bin/hermes-browser";
    icon = "chromium";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    settings.Keywords = "Hermes;Chromium;Browser;SSH;CDP;";
  };

  home.packages = [
    toggle-audio
    toggle-mute
    toggle-mute-zen
    inc-volume-zen
    dec-volume-zen
    toggle-tv
    prepare-game
    hermes-browser
  ];
}
