{ pkgs, ... }:
let
  colors = import ./colors.nix;
  wallpaper = ./assets/wallpaper.png;

  # Generate blurred wallpaper for lock screen
  blurredWallpaper = pkgs.runCommand "hyprlock-blurred-wallpaper.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    convert ${wallpaper} -blur 0x50 -brightness-contrast -10x-10 $out
  '';
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          path = "${blurredWallpaper}";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "200, 50";
          dots_size = 0.33;
          dots_spacing = 0.15;
          dots_center = true;
          dots_rounding = -1;
          inner_color = "rgb(${builtins.substring 1 6 colors.primary})";
          font_color = "rgb(${builtins.substring 1 6 colors.onPrimary})";
          font_family = "Fira Sans Semibold";
          outer_color = "rgb(${builtins.substring 1 6 colors.onPrimary})";
          outline_thickness = 3;
          fade_on_empty = true;
          fade_timeout = 1000;
          placeholder_text = "<i>Input Password...</i>";
          hide_input = false;
          rounding = 10;
          check_color = "rgb(${builtins.substring 1 6 colors.primary})";
          fail_color = "rgb(${builtins.substring 1 6 colors.error})";
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          capslock_color = -1;
          numlock_color = -1;
          bothlock_color = -1;
          invert_numlock = false;
          swap_font_color = false;
          position = "0, -20";
          halign = "center";
          valign = "center";
          shadow_passes = 10;
          shadow_size = 20;
          shadow_color = "rgb(${builtins.substring 1 6 colors.shadow})";
          shadow_boost = 1.6;
        }
      ];

      label = [
        # Clock
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$TIME\"";
          color = "rgb(255, 255, 255)";
          font_size = 70;
          font_family = "Fira Sans Bold";
          position = "-50, 20";
          halign = "right";
          valign = "bottom";
          shadow_passes = 5;
          shadow_size = 10;
        }
        # User
        {
          monitor = "";
          text = "$USER";
          color = "rgb(255, 255, 255)";
          font_size = 20;
          font_family = "Fira Sans";
          position = "-50, 120";
          halign = "right";
          valign = "bottom";
          shadow_passes = 5;
          shadow_size = 10;
        }
      ];

      image = [
        {
          monitor = "";
          path = "${wallpaper}";
          size = 280;
          rounding = 40;
          border_size = 4;
          border_color = "rgb(${builtins.substring 1 6 colors.primary})";
          rotate = 0;
          reload_time = -1;
          position = "0, 200";
          halign = "center";
          valign = "center";
          shadow_passes = 10;
          shadow_size = 20;
          shadow_color = "rgb(${builtins.substring 1 6 colors.shadow})";
          shadow_boost = 1.6;
        }
      ];
    };
  };
}
