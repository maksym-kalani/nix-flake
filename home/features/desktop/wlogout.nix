{ config, pkgs, ... }:
let
  c = config.lib.stylix.colors;

  # Generate blurred wallpaper at build time from stylix image
  blurredWallpaper =
    pkgs.runCommand "wlogout-blurred-wallpaper.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert ${config.stylix.image} -blur 0x50 -brightness-contrast -10x-10 $out
      '';

  # Wlogout launcher script with dynamic margins based on monitor
  wlogoutScript = pkgs.writeShellScriptBin "wlogout-launcher" ''
    monitor=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq '.[] | select(.focused==true)')
    res_w=$(echo "$monitor" | ${pkgs.jq}/bin/jq '.width')
    res_h=$(echo "$monitor" | ${pkgs.jq}/bin/jq '.height')
    scale_pct=$(echo "$monitor" | ${pkgs.jq}/bin/jq '(.scale * 100) | round')

    screen_w=$((res_w * 100 / scale_pct))
    screen_h=$((res_h * 100 / scale_pct))
    v_margin=$((screen_h * 27 / 100))
    button_size=$((screen_h - 2 * v_margin))
    h_margin=$(((screen_w - button_size * 3) / 2))

    if [ "$h_margin" -lt 0 ]; then
      h_margin=0
    fi

    wlogout -b 3 -T "$v_margin" -B "$v_margin" -L "$h_margin" -R "$h_margin"
  '';
in
{
  home.packages = [ wlogoutScript ];

  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "logout";
        action = "loginctl terminate-session $XDG_SESSION_ID";
        text = "Log Out";
        keybind = "e";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Restart";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Power Off";
        keybind = "s";
      }
    ];

    style = ''
      * {
        font-family: "Inter", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
        background-image: none;
        transition: 20ms;
        box-shadow: none;
      }

      window {
        background: url("${blurredWallpaper}");
        background-size: cover;
        font-size: 14pt;
      }

      button {
        background-repeat: no-repeat;
        background-position: center 35%;
        background-size: 25%;
        border-radius: 20px;
        border: 1px solid rgba(255, 255, 255, 0.1);
        margin: 10px;
        transition: all 0.3s ease-in-out;
        color: #${c.base05};
        background-color: alpha(#${c.base0D}, 0.15);
      }

      button:focus {
        background-color: alpha(#${c.base0D}, 0.3);
        border: 1px solid rgba(255, 255, 255, 0.2);
      }

      button:hover {
        background-color: alpha(#${c.base0D}, 0.4);
        border: 1px solid rgba(255, 255, 255, 0.3);
      }

      #logout {
        background-image: image(url("${./assets/logout.png}"));
      }

      #shutdown {
        background-image: image(url("${./assets/shutdown.png}"));
      }

      #reboot {
        background-image: image(url("${./assets/reboot.png}"));
      }
    '';
  };
}
