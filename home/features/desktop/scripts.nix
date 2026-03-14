# Custom scripts for desktop environment
{ pkgs, ... }:
let
  toggle-audio = pkgs.writeShellScriptBin "toggle-audio" ''
    # toggle-audio — cycle through all sinks, move streams, and notify
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
    # toggle-mute — toggle default source mute and notify
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
    # toggle-mute-zen — find the Zen audio stream and toggle its mute state
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
    # inc-volume-zen — increase Zen browser volume
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
    # dec-volume-zen — decrease Zen browser volume
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
    # toggle-tv — toggle HDMI-A-1 display + audio sink
    set -euo pipefail

    MON="HDMI-A-1"
    PLACEMENT="3840x2160@60,-3840x0,1"
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
      hyprctl keyword monitor "$MON,$PLACEMENT" >/dev/null
      for _ in {1..40}; do
        sink_exists "$HDMI_SINK" && break
        sleep 0.25
      done
      switch_sink "$HDMI_SINK" || true
      ${pkgs.libnotify}/bin/notify-send "🖥️ TV ON" "$MON enabled; audio → HDMI"
    }

    disable_tv() {
      hyprctl keyword monitor "$MON,disable" >/dev/null
      switch_sink "$USB_SINK" || true
      ${pkgs.libnotify}/bin/notify-send "🖥️ TV OFF" "$MON disabled; audio → USB DAC"
    }

    mon_json="$(hyprctl -j monitors 2>/dev/null || echo '[]')"
    mon_entry="$(${pkgs.jq}/bin/jq -r --arg n "$MON" '.[] | select(.name==$n)' <<<"$mon_json" || true)"

    mon_present=false
    mon_dpms=true
    if [[ -n "''${mon_entry}" ]]; then
      mon_present=true
      mon_dpms="$(${pkgs.jq}/bin/jq -r 'if has("dpmsStatus") then .dpmsStatus else true end' <<<"$mon_entry")"
    fi

    cur_sink="$(${pkgs.pulseaudio}/bin/pactl info | ${pkgs.gawk}/bin/awk -F': ' '/Default Sink/ {print $2}')"
    hdmi_sink_present=false
    sink_exists "$HDMI_SINK" && hdmi_sink_present=true

    tv_on=false
    if [[ "$mon_present" == true && "$mon_dpms" == "true" && "$hdmi_sink_present" == true && "$cur_sink" == "$HDMI_SINK" ]]; then
      tv_on=true
    fi

    if [[ "$tv_on" == true ]]; then
      disable_tv
    else
      enable_tv
    fi
  '';

  prepare-game = pkgs.writeShellScriptBin "prepare-game" ''
    # prepare-game — spawn and arrange gaming layout
    hyprctl dispatch workspace number 1
    vesktop &
    zen-browser --new-instance https://kavita.laufin.xyz/home &
    sleep 0.5
    hyprctl dispatch workspace number 8
    zen-browser --new-instance https://www.owlbear.rodeo/profile &
    sleep 0.5
    hyprctl dispatch workspace number 1
  '';
in
{
  home.packages = [
    toggle-audio
    toggle-mute
    toggle-mute-zen
    inc-volume-zen
    dec-volume-zen
    toggle-tv
    prepare-game
  ];
}
