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
in
{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "hyprctl dispatch exit";
        text = "Log Out";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
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

      #lock {
        background-image: image(url("${./assets/lock.png}"));
      }

      #logout {
        background-image: image(url("${./assets/logout.png}"));
      }

      #suspend {
        background-image: image(url("${./assets/suspend.png}"));
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
