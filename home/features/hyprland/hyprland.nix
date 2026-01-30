{ config, pkgs, lib, ... }:

let
  wallpaper = ./assets/wallpaper.png;
in
{
  # Hyprpaper wallpaper service
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "${wallpaper}" ];
      wallpaper = [
        ",${wallpaper}"           # Fallback for all monitors
        "Virtual-1,${wallpaper}"  # VirtualBox display
      ];
      splash = false;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      monitor = [
        "DP-2,3440x1440@144,0x0,1"
        "DP-3,1920x1080@100,3440x0,1,transform,3"
        # Fallback for VMs and unknown monitors
        ",preferred,auto,1"
      ];

      workspace = [
        "1,monitor:DP-2"
        "2,monitor:DP-2"
        "3,monitor:DP-2"
        "4,monitor:DP-2"
        "5,monitor:DP-2"
        "6,monitor:DP-2"
        "7,monitor:DP-3"
        "8,monitor:DP-3"
        "9,monitor:DP-3"
        "10,monitor:HDMI-A-1"
      ];

      "$mainMod" = "ALT";
      "$terminal" = "kitty";
      "$browser" = "firefox";
      "$fileManager" = "nautilus";

      "$background" = "rgba(121318ff)";
      "$primary" = "rgba(b8c3ffff)";
      "$on_surface" = "rgba(e3e1e9ff)";
      "$error" = "rgba(ffb4abff)";

      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
        "LIBGL_ALWAYS_SOFTWARE,1"

        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "GDK_SCALE,1"
        "GDK_BACKEND,wayland,x11,*"
        "CLUTTER_BACKEND,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "OZONE_PLATFORM,wayland"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "SDL_VIDEODRIVER,wayland"
      ];

      input = {
        kb_layout = "us,ua";
        kb_options = "grp:win_space_toggle";
        numlock_by_default = true;
        follow_mouse = 1;
        mouse_refocus = false;
        sensitivity = 0;

        touchpad = {
          natural_scroll = false;
          scroll_factor = 1.0;
        };
      };

      general = {
        gaps_in = 10;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "$on_surface";
        "col.inactive_border" = "$primary";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.9;
        fullscreen_opacity = 1.0;

        blur = {
          enabled = true;
          size = 3;
          passes = 4;
          new_optimizations = true;
          ignore_opacity = true;
          xray = true;
        };

        shadow = {
          enabled = true;
          range = 10;
          render_power = 2;
          color = "0x33000000";
        };
      };

      animations = {
        enabled = true;

        bezier = [
          "linear, 0, 0, 1, 1"
          "md3_standard, 0.2, 0, 0, 1"
          "md3_decel, 0.05, 0.7, 0.1, 1"
          "md3_accel, 0.3, 0, 0.8, 0.15"
          "overshot, 0.05, 0.9, 0.1, 1.1"
          "crazyshot, 0.1, 1.5, 0.76, 0.92"
          "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
          "menu_decel, 0.1, 1, 0, 1"
          "menu_accel, 0.38, 0.04, 1, 0.07"
          "easeInOutCirc, 0.85, 0, 0.15, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutExpo, 0.16, 1, 0.3, 1"
          "softAcDecel, 0.26, 0.26, 0.15, 1"
          "md2, 0.4, 0, 0.2, 1"
        ];

        animation = [
          "windows, 1, 3, md3_decel, popin 60%"
          "windowsIn, 1, 3, md3_decel, popin 60%"
          "windowsOut, 1, 3, md3_accel, popin 60%"
          "border, 1, 10, default"
          "fade, 1, 3, md3_decel"
          "layersIn, 1, 3, menu_decel, slide"
          "layersOut, 1, 1.6, menu_accel"
          "fadeLayersIn, 1, 2, menu_decel"
          "fadeLayersOut, 1, 4.5, menu_accel"
          "workspaces, 1, 7, menu_decel, slide"
          "specialWorkspace, 1, 3, md3_decel, slidevert"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = { };

      binds = {
        workspace_back_and_forth = false;
        allow_workspace_cycles = true;
        pass_mouse_when_bound = false;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        initial_workspace_tracking = 1;
      };

      xwayland = {
        force_zero_scaling = true;
      };

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "hyprctl setcursor Bibata-Modern-Ice 24"
        "swaync"
        "hypridle"
        "hyprpaper"
        "waybar"
        "wl-paste --watch cliphist store"
      ];

      bind = [
        # Applications
        "$mainMod, RETURN, exec, $terminal"
        "$mainMod, B, exec, $browser"
        "$mainMod, E, exec, $fileManager"
        "$mainMod CTRL, RETURN, exec, pkill rofi || rofi -show drun -replace -i"

        # Windows
        "$mainMod, Q, killactive"
        "$mainMod SHIFT, Q, exec, hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"
        "$mainMod, F, fullscreen, 0"
        "$mainMod, M, fullscreen, 1"
        "$mainMod, T, togglefloating"
        "$mainMod SHIFT, T, workspaceopt, allfloat"
        "$mainMod, J, togglesplit"
        "$mainMod, G, togglegroup"
        "$mainMod, K, swapsplit"

        # Focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Swap windows
        "$mainMod ALT, left, swapwindow, l"
        "$mainMod ALT, right, swapwindow, r"
        "$mainMod ALT, up, swapwindow, u"
        "$mainMod ALT, down, swapwindow, d"

        # Resize
        "$mainMod SHIFT, right, resizeactive, 100 0"
        "$mainMod SHIFT, left, resizeactive, -100 0"
        "$mainMod SHIFT, down, resizeactive, 0 100"
        "$mainMod SHIFT, up, resizeactive, 0 -100"

        # Actions
        "$mainMod CTRL, R, exec, hyprctl reload"
        "$mainMod CTRL, Q, exec, wlogout"
        "$mainMod CTRL, L, exec, hyprlock"
        "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
        "$mainMod SHIFT, B, exec, pkill waybar || waybar"

        # Screenshot
        ", PRINT, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mainMod, PRINT, exec, grim - | wl-copy"
        "$mainMod SHIFT, PRINT, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"

        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Workspace navigation
        "$mainMod, Tab, workspace, m+1"
        "$mainMod SHIFT, Tab, workspace, m-1"
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        "$mainMod CTRL, down, workspace, empty"

        # Zoom
        "$mainMod SHIFT, Z, exec, hyprctl keyword cursor:zoom_factor 1"

        # Custom applications
        "$mainMod, D, exec, vesktop"
        "$mainMod, L, exec, telegram-desktop"
        "$mainMod, S, exec, steam"

        # Group navigation
        "$mainMod CTRL, 113, changegroupactive, f"
        "$mainMod CTRL, 114, changegroupactive, b"

        # Fn keys
        ", XF86MonBrightnessUp, exec, brightnessctl -q s +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl -q s 10%-"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPause, exec, playerctl pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle"
        ", XF86Lock, exec, hyprlock"
      ];

      binde = [
        "ALT, Tab, cyclenext"
        "ALT, Tab, bringactivetotop"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      layerrule2 = [
        "blur, waybar"
        "blur, swaync-control-center"
        "blur, swaync-notification-window"
        "ignorezero, swaync-control-center"
        "ignorezero, swaync-notification-window"
        "ignorealpha 0.5, swaync-control-center"
        "ignorealpha 0.5, swaync-notification-window"
      ];

      windowrulev2 = [
        # Pavucontrol
        "float, class:(.*org.pulseaudio.pavucontrol.*)"
        "center, class:(.*org.pulseaudio.pavucontrol.*)"
        "pin, class:(.*org.pulseaudio.pavucontrol.*)"
        "size 700 600, class:(.*org.pulseaudio.pavucontrol.*)"

        # Waypaper
        "float, class:(.*waypaper.*)"
        "center, class:(.*waypaper.*)"
        "pin, class:(.*waypaper.*)"
        "size 900 700, class:(.*waypaper.*)"

        # Blueman Manager
        "float, class:(blueman-manager)"
        "center, class:(blueman-manager)"
        "size 800 600, class:(blueman-manager)"

        # nwg-look
        "float, class:(nwg-look)"
        "center, class:(nwg-look)"
        "size 700 600, class:(nwg-look)"

        # nwg-displays
        "float, class:(nwg-displays)"
        "center, class:(nwg-displays)"
        "size 900 600, class:(nwg-displays)"

        # Gnome Calculator
        "float, class:(org.gnome.Calculator)"
        "center, class:(org.gnome.Calculator)"
        "size 700 600, class:(org.gnome.Calculator)"

        # Hyprland Share Picker
        "float, class:(hyprland-share-picker)"
        "pin, class:(hyprland-share-picker)"
        "center, class:(hyprland-share-picker)"
        "size 600 400, class:(hyprland-share-picker)"

        # nm-connection-editor
        "float, class:(nm-connection-editor)"
        "center, class:(nm-connection-editor)"
        "size 800 700, class:(nm-connection-editor)"

        # Picture-in-Picture
        "float, title:(Picture-in-Picture)"
        "pin, title:(Picture-in-Picture)"
        "center, title:(Picture-in-Picture)"

        # Steam
        "float, class:^(steam)$"
        "tile, class:^(steam)$, title:^(Steam)$"
        "workspace 10, class:^(steam)$, title:.*Big Picture.*"
        "fullscreen, class:^(steam)$, title:.*Big Picture.*"

        # Bitwarden
        "float, title:.*Bitwarden Password Manager.*"
      ];
    };
  };

  # Required packages
  home.packages = with pkgs; [
    # Core Hyprland ecosystem
    hyprlock
    hypridle
    hyprpaper
    xdg-desktop-portal-hyprland

    # Notifications
    swaynotificationcenter

    # Launchers & menus
    wlogout

    # Clipboard
    cliphist
    wl-clipboard

    # Authentication
    polkit_gnome

    # System controls
    brightnessctl
    playerctl
    wireplumber
    pulseaudio

    # Screenshots
    grim
    slurp
    swappy

    # Wallpaper
    waypaper

    # Settings
    nwg-look
    nwg-displays

    # Cursor theme
    bibata-cursors
  ];

  # Cursor configuration
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };
}
