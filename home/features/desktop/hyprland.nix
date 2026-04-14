{
  config,
  pkgs,
  ...
}:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      monitor = [
        "DP-1,3440x1440@144,0x0,1"
        "DP-2,1920x1080@100,3440x0,1,transform,3"
        "HDMI-A-1,disable"
      ];

      workspace = [
        "1,monitor:DP-1"
        "2,monitor:DP-1"
        "3,monitor:DP-1"
        "4,monitor:DP-1"
        "5,monitor:DP-1"
        "6,monitor:DP-1"
        "7,monitor:DP-2"
        "8,monitor:DP-2"
        "9,monitor:DP-2"
        "10,monitor:HDMI-A-1"
      ];

      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      "$browser" = "zen";
      "$fileManager" = "nautilus";

      env = [
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
        sensitivity = -1;

        touchpad = {
          natural_scroll = false;
          scroll_factor = 1.0;
        };
      };

      general = {
        gaps_in = 10;
        gaps_out = 20;
        border_size = 2;
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
        "dbus-update-activation-environment --systemd --all"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "hyprctl setcursor Bibata-Modern-Ice 24"
        "swaync"
        "swaybg -i ${config.stylix.image} -m fill"
        "waybar"
        "wl-paste --watch cliphist store"
        #"gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\""
      ];

      bind = [
        # Applications
        "$mainMod, RETURN, exec, $terminal"
        "$mainMod, B, exec, $browser"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, A, exec, vicinae toggle"

        # Windows
        "$mainMod, Q, killactive"
        "$mainMod SHIFT, Q, exec, hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"
        "$mainMod, F, fullscreen, 0"
        "$mainMod, M, fullscreen, 1"
        "$mainMod, T, togglefloating"
        "$mainMod SHIFT, T, workspaceopt, allfloat"
        "$mainMod, J, layoutmsg, togglesplit"
        "$mainMod, G, togglegroup"
        "$mainMod, K, layoutmsg, swapsplit"

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
        "$mainMod CTRL, Q, exec, wlogout-launcher"
        "$mainMod CTRL, L, exec, loginctl terminate-session $XDG_SESSION_ID"
        "$mainMod, V, exec, vicinae vicinae://extensions/vicinae/clipboard/history"
        "$mainMod SHIFT, B, exec, pkill waybar || waybar"

        # Screenshot
        ", PRINT, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mainMod, PRINT, exec, grim -g \"$(slurp)\" - | satty --filename -"
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
        "$mainMod, TAB, togglespecialworkspace"

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
        "$mainMod, L, exec, Telegram"
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
        ", XF86Lock, exec, loginctl terminate-session $XDG_SESSION_ID"

        # Custom scripts (macro keys)
        ", code:201, exec, toggle-audio"
        ", code:202, exec, toggle-mute"
        ", code:197, exec, toggle-mute-zen"
        ", code:195, exec, dec-volume-zen"
        ", code:196, exec, inc-volume-zen"
        ", code:192, exec, prepare-game"
        ", code:193, exec, toggle-tv"
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

      layerrule = [
        "blur on, match:namespace waybar"
        "blur on, match:namespace swaync-control-center"
        "blur on, match:namespace swaync-notification-window"
        "blur on, match:namespace vicinae"
        "ignore_alpha 0.01, match:namespace waybar"
        "ignore_alpha 0, match:namespace swaync-control-center"
        "ignore_alpha 0, match:namespace swaync-notification-window"
        "ignore_alpha 0, match:namespace vicinae"
        "animation slide top, match:namespace swaync-control-center"
      ];

      windowrule = [
        # Pavucontrol
        "float on, pin on, center on, match:class (.*org.pulseaudio.pavucontrol.*)"
        "size 700 600, match:class (.*org.pulseaudio.pavucontrol.*)"
        "animation slide top, match:class (.*org.pulseaudio.pavucontrol.*)"

        # Satty
        "float on, pin on, center on, match:class (.*satty.*)"
        "size 900 700, match:class (.*satty.*)"

        # Blueman Manager
        "float on, center on, match:title (Bluetooth Devices)"
        "size 800 600, match:title (Bluetooth Devices)"
        "animation slide top, match:title (Bluetooth Devices)"

        # nwg-look
        "float on, center on, match:class (nwg-look)"
        "size 700 600, match:class (nwg-look)"

        # nwg-displays
        "float on, center on, match:class (nwg-displays)"
        "size 900 600, match:class (nwg-displays)"

        # Gnome Calculator
        "float on, center on, match:class (org.gnome.Calculator)"
        "size 700 600, match:class (org.gnome.Calculator)"

        # Hyprland Share Picker
        "float on, pin on, center on, match:class (hyprland-share-picker)"
        "size 600 400, match:class (hyprland-share-picker)"

        # nm-connection-editor
        "float on, center on, match:class (nm-connection-editor)"
        "size 800 700, match:class (nm-connection-editor)"
        "animation slide top, match:class (nm-connection-editor)"

        # Picture-in-Picture
        "float on, center on, pin on, match:title (Picture-in-Picture)"

        # Steam
        "float on, match:class ^(steam)$"
        "tile on, match:class ^(steam)$, match:title ^(Steam)$"
        "workspace 10, match:class ^(steam)$, match:title .*Big Picture.*"
        "fullscreen on, match:class ^(steam)$, match:title .*Big Picture.*"

        # Bitwarden
        "float on, match:title .*Bitwarden Password Manager.*"

        # Calendar
        "float on, match:class (org.gnome.Calendar)"
        "size 400 600, match:class (org.gnome.Calendar)"
        "move 3020 70, match:class (org.gnome.Calendar)"
        "animation slide top, match:class (org.gnome.Calendar)"
      ];
    };
  };

}
