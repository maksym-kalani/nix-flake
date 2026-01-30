{pkgs, ...}:
let
  colors = import ./colors.nix;
  wallpaper = ./assets/wallpaper.png;

  # Generate blurred wallpaper at build time
  blurredWallpaper = pkgs.runCommand "wlogout-blurred-wallpaper.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    convert ${wallpaper} -blur 0x50 -brightness-contrast -10x-10 $out
  '';

  # Wlogout launcher script with dynamic margins based on monitor
  wlogoutScript = pkgs.writeShellScriptBin "wlogout-launcher" ''
    res_h=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq '.[] | select(.focused==true) | .height')
    h_scale=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')
    w_margin=$((res_h * 27 / h_scale))
    wlogout -b 3 -T $w_margin -B $w_margin
  '';
in
{
  home.packages = [ wlogoutScript ];

  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "logout";
        action = "hyprctl dispatch exit";
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
        font-family: "Fira Sans Semibold", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
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
        color: ${colors.foreground};
        background-color: alpha(${colors.primary}, 0.15);
      }

      button:focus {
        background-color: alpha(${colors.primary}, 0.3);
        border: 1px solid rgba(255, 255, 255, 0.2);
      }

      button:hover {
        background-color: alpha(${colors.primary}, 0.4);
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
