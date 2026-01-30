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
        font-size: 16pt;
      }

      button {
        background-repeat: no-repeat;
        background-position: center;
        background-size: 20%;
        animation: gradient_f 20s ease-in infinite;
        border-radius: 80px;
        border: 0px;
        transition: all 0.3s cubic-bezier(.55, 0.0, .28, 1.682), box-shadow 0.2s ease-in-out, background-color 0.2s ease-in-out;
        color: ${colors.foreground};
        background-color: alpha(${colors.primary}, 0.2);
      }

      button:focus {
        background-color: alpha(${colors.primary}, 0.5);
        background-size: 25%;
        border: 0px;
      }

      button:hover {
        background-color: alpha(${colors.primary}, 0.9);
        opacity: 0.8;
        color: ${colors.onPrimary};
        background-size: 30%;
        margin: 30px;
        border-radius: 80px;
        box-shadow: 0 0 50px ${colors.shadow};
      }

      button span {
        font-size: 1.2em;
      }

      #lock {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${./assets/lock.png}"));
      }

      #logout {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${./assets/logout.png}"));
      }

      #suspend {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${./assets/suspend.png}"));
      }

      #shutdown {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${./assets/shutdown.png}"));
      }

      #reboot {
        margin: 10px;
        border-radius: 20px;
        background-image: image(url("${./assets/reboot.png}"));
      }
    '';
  };
}
