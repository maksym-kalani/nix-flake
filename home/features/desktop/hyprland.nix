{
  config,
  pkgs,
  lib,
  ...
}:
let
  raw = lib.generators.mkLuaInline;

  dsp = {
    exec = cmd: raw ''hl.dsp.exec_cmd("${cmd}")'';
    close = raw "hl.dsp.window.close()";
    float = raw ''hl.dsp.window.float({ action = "toggle" })'';
    fullscreen = n: raw "hl.dsp.window.fullscreen(${toString n})";
    layout = msg: raw ''hl.dsp.layout("${msg}")'';
    focus = dir: raw ''hl.dsp.focus({ direction = "${dir}" })'';
    swap = dir: raw ''hl.dsp.window.swap({ direction = "${dir}" })'';
    group = {
      toggle = raw "hl.dsp.group.toggle()";
      next = raw "hl.dsp.group.next()";
      prev = raw "hl.dsp.group.prev()";
    };
    focusWorkspace = ws: raw ''hl.dsp.focus({ workspace = "${toString ws}" })'';
    moveToWorkspace = ws: raw ''hl.dsp.window.move({ workspace = "${toString ws}" })'';
    toggleSpecial = raw "hl.dsp.workspace.toggle_special()";
    drag = raw "hl.dsp.window.drag()";
    resize = raw "hl.dsp.window.resize()";
    raw = cmd: raw ''hl.dsp.exec_raw("${cmd}")'';
  };

  bind' = keys: dispatcher: {
    _args = [
      keys
      dispatcher
    ];
  };
  bindOpts' = keys: dispatcher: opts: {
    _args = [
      keys
      dispatcher
      opts
    ];
  };

  envEntry =
    pair:
    let
      parts = lib.splitString "," pair;
    in
    {
      _args = [
        (builtins.head parts)
        (lib.concatStringsSep "," (builtins.tail parts))
      ];
    };

  workspaceBinds = lib.concatMap (
    i:
    let
      key = toString (lib.mod i 10);
    in
    [
      (bind' "SUPER + ${key}" (dsp.focusWorkspace i))
      (bind' "SUPER + SHIFT + ${key}" (dsp.moveToWorkspace i))
    ]
  ) (lib.range 1 10);
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    configType = "lua";

    settings = {
      monitor = [
        {
          output = "";
          disabled = true;
        }
        {
          output = "DP-1";
          mode = "3440x1440@144";
          position = "0x0";
          scale = 1;
        }
        {
          output = "DP-2";
          mode = "1920x1080@100";
          position = "3440x0";
          scale = 1;
          transform = 3;
        }
      ];

      workspace_rule = builtins.genList (
        i:
        let
          n = i + 1;
        in
        {
          workspace = toString n;
          monitor =
            if n <= 6 then
              "DP-1"
            else if n <= 9 then
              "DP-2"
            else
              "HDMI-A-1";
        }
      ) 10;

      env = map envEntry [
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

      config = {
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
          "col.active_border" = "rgb(${config.lib.stylix.colors.base0D})";
          "col.inactive_border" = "rgb(${config.lib.stylix.colors.base03})";
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
            color = "rgba(${config.lib.stylix.colors.base00}99)";
          };
        };

        animations = {
          enabled = true;
        };

        dwindle = {
          preserve_split = true;
        };

        binds = {
          workspace_back_and_forth = false;
          allow_workspace_cycles = true;
          pass_mouse_when_bound = false;
        };

        group = {
          "col.border_active" = "rgb(${config.lib.stylix.colors.base0D})";
          "col.border_inactive" = "rgb(${config.lib.stylix.colors.base03})";
          "col.border_locked_active" = "rgb(${config.lib.stylix.colors.base0C})";
          groupbar = {
            "col.active" = "rgb(${config.lib.stylix.colors.base0D})";
            "col.inactive" = "rgb(${config.lib.stylix.colors.base03})";
            text_color = "rgb(${config.lib.stylix.colors.base05})";
          };
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          initial_workspace_tracking = 1;
          background_color = "rgb(${config.lib.stylix.colors.base00})";
        };

        xwayland = {
          force_zero_scaling = true;
        };
      };

      # Bezier curve definitions (separate from config block)
      curve = [
        {
          _args = [
            "linear"
            {
              type = "bezier";
              points = [
                [
                  0
                  0
                ]
                [
                  1
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "md3_standard"
            {
              type = "bezier";
              points = [
                [
                  0.2
                  0
                ]
                [
                  0
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "md3_decel"
            {
              type = "bezier";
              points = [
                [
                  0.05
                  0.7
                ]
                [
                  0.1
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "md3_accel"
            {
              type = "bezier";
              points = [
                [
                  0.3
                  0
                ]
                [
                  0.8
                  0.15
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "overshot"
            {
              type = "bezier";
              points = [
                [
                  0.05
                  0.9
                ]
                [
                  0.1
                  1.1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "crazyshot"
            {
              type = "bezier";
              points = [
                [
                  0.1
                  1.5
                ]
                [
                  0.76
                  0.92
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "hyprnostretch"
            {
              type = "bezier";
              points = [
                [
                  0.05
                  0.9
                ]
                [
                  0.1
                  1.0
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "menu_decel"
            {
              type = "bezier";
              points = [
                [
                  0.1
                  1
                ]
                [
                  0
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "menu_accel"
            {
              type = "bezier";
              points = [
                [
                  0.38
                  0.04
                ]
                [
                  1
                  0.07
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "easeInOutCirc"
            {
              type = "bezier";
              points = [
                [
                  0.85
                  0
                ]
                [
                  0.15
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "easeOutCirc"
            {
              type = "bezier";
              points = [
                [
                  0
                  0.55
                ]
                [
                  0.45
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "easeOutExpo"
            {
              type = "bezier";
              points = [
                [
                  0.16
                  1
                ]
                [
                  0.3
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "softAcDecel"
            {
              type = "bezier";
              points = [
                [
                  0.26
                  0.26
                ]
                [
                  0.15
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "md2"
            {
              type = "bezier";
              points = [
                [
                  0.4
                  0
                ]
                [
                  0.2
                  1
                ]
              ];
            }
          ];
        }
      ];

      # Animation definitions (separate from config block)
      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 3;
          bezier = "md3_decel";
          style = "popin 60%";
        }
        {
          leaf = "windowsIn";
          enabled = true;
          speed = 3;
          bezier = "md3_decel";
          style = "popin 60%";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 3;
          bezier = "md3_accel";
          style = "popin 60%";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 3;
          bezier = "md3_decel";
        }
        {
          leaf = "layersIn";
          enabled = true;
          speed = 3;
          bezier = "menu_decel";
          style = "slide";
        }
        {
          leaf = "layersOut";
          enabled = true;
          speed = 1.6;
          bezier = "menu_accel";
        }
        {
          leaf = "fadeLayersIn";
          enabled = true;
          speed = 2;
          bezier = "menu_decel";
        }
        {
          leaf = "fadeLayersOut";
          enabled = true;
          speed = 4.5;
          bezier = "menu_accel";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 7;
          bezier = "menu_decel";
          style = "slide";
        }
        {
          leaf = "specialWorkspace";
          enabled = true;
          speed = 3;
          bezier = "md3_decel";
          style = "slidevert";
        }
      ];

      bind = [
        # Applications
        (bind' "SUPER + RETURN" (dsp.exec "kitty"))
        (bind' "SUPER + B" (dsp.exec "zen"))
        (bind' "SUPER + E" (dsp.exec "nautilus"))
        (bind' "SUPER + A" (dsp.exec "vicinae toggle"))

        # Windows
        (bind' "SUPER + Q" dsp.close)
        (bind' "SUPER + SHIFT + Q" (dsp.exec "hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"))
        (bind' "SUPER + F" (dsp.fullscreen 0))
        (bind' "SUPER + M" (dsp.fullscreen 1))
        (bind' "SUPER + T" dsp.float)
        (bind' "SUPER + SHIFT + T" (dsp.raw "workspaceopt allfloat"))
        (bind' "SUPER + J" (dsp.layout "togglesplit"))
        (bind' "SUPER + G" dsp.group.toggle)
        (bind' "SUPER + K" (dsp.layout "swapsplit"))

        # Focus
        (bind' "SUPER + left" (dsp.focus "left"))
        (bind' "SUPER + right" (dsp.focus "right"))
        (bind' "SUPER + up" (dsp.focus "up"))
        (bind' "SUPER + down" (dsp.focus "down"))

        # Swap windows
        (bind' "SUPER + ALT + left" (dsp.swap "left"))
        (bind' "SUPER + ALT + right" (dsp.swap "right"))
        (bind' "SUPER + ALT + up" (dsp.swap "up"))
        (bind' "SUPER + ALT + down" (dsp.swap "down"))

        # Resize
        (bind' "SUPER + SHIFT + right" (dsp.raw "resizeactive 100 0"))
        (bind' "SUPER + SHIFT + left" (dsp.raw "resizeactive -100 0"))
        (bind' "SUPER + SHIFT + down" (dsp.raw "resizeactive 0 100"))
        (bind' "SUPER + SHIFT + up" (dsp.raw "resizeactive 0 -100"))

        # Actions
        (bind' "SUPER + CTRL + R" (dsp.exec "hyprctl reload"))
        (bind' "SUPER + CTRL + Q" (dsp.exec "wlogout-launcher"))
        (bind' "SUPER + CTRL + L" (dsp.exec "loginctl terminate-session $XDG_SESSION_ID"))
        (bind' "SUPER + V" (dsp.exec "vicinae vicinae://extensions/vicinae/clipboard/history"))
        (bind' "SUPER + SHIFT + B" (dsp.exec "pkill waybar || waybar"))

        # Screenshot
        (bind' "PRINT" (raw ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")''))
        (bind' "SUPER + PRINT" (raw ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty --filename -")''))
        (bind' "SUPER + SHIFT + PRINT" (
          raw ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png")''
        ))

        # Special workspace
        (bind' "SUPER + TAB" dsp.toggleSpecial)

        # Workspace navigation
        (bind' "SUPER + Tab" (dsp.focusWorkspace "e+1"))
        (bind' "SUPER + SHIFT + Tab" (dsp.focusWorkspace "e-1"))
        (bind' "SUPER + mouse_down" (dsp.focusWorkspace "e+1"))
        (bind' "SUPER + mouse_up" (dsp.focusWorkspace "e-1"))
        (bind' "SUPER + CTRL + down" (dsp.focusWorkspace "empty"))

        # Zoom
        (bind' "SUPER + SHIFT + Z" (dsp.exec "hyprctl keyword cursor:zoom_factor 1"))

        # Custom applications
        (bind' "SUPER + D" (dsp.exec "vesktop"))
        (bind' "SUPER + L" (dsp.exec "Telegram"))
        (bind' "SUPER + S" (dsp.exec "steam"))

        # Group navigation
        (bind' "SUPER + CTRL + code:113" dsp.group.next)
        (bind' "SUPER + CTRL + code:114" dsp.group.prev)

        # Fn keys
        (bind' "XF86MonBrightnessUp" (dsp.exec "brightnessctl -q s +10%"))
        (bind' "XF86MonBrightnessDown" (dsp.exec "brightnessctl -q s 10%-"))
        (bind' "XF86AudioMute" (dsp.exec "pactl set-sink-mute @DEFAULT_SINK@ toggle"))
        (bind' "XF86AudioPlay" (dsp.exec "playerctl play-pause"))
        (bind' "XF86AudioPause" (dsp.exec "playerctl pause"))
        (bind' "XF86AudioNext" (dsp.exec "playerctl next"))
        (bind' "XF86AudioPrev" (dsp.exec "playerctl previous"))
        (bind' "XF86AudioMicMute" (dsp.exec "pactl set-source-mute @DEFAULT_SOURCE@ toggle"))

        # Custom scripts (macro keys)
        (bind' "code:201" (dsp.exec "toggle-audio"))
        (bind' "code:202" (dsp.exec "toggle-mute"))
        (bind' "code:197" (dsp.exec "toggle-mute-zen"))
        (bind' "code:195" (dsp.exec "dec-volume-zen"))
        (bind' "code:196" (dsp.exec "inc-volume-zen"))
        (bind' "code:192" (dsp.exec "prepare-game"))
        (bind' "code:193" (dsp.exec "toggle-tv"))

        # Volume (repeating)
        (bindOpts' "XF86AudioRaiseVolume" (dsp.exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+") {
          repeating = true;
        })
        (bindOpts' "XF86AudioLowerVolume" (dsp.exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-") {
          repeating = true;
        })

        # Cycle windows (repeating)
        (bindOpts' "ALT + Tab" (raw "hl.dsp.window.cycle_next()") { repeating = true; })
        (bindOpts' "ALT + Tab" (raw "hl.dsp.window.bring_to_top()") { repeating = true; })

        # Mouse move/resize
        (bindOpts' "SUPER + mouse:272" dsp.drag { mouse = true; })
        (bindOpts' "SUPER + mouse:273" dsp.resize { mouse = true; })
      ]
      ++ workspaceBinds;

      layer_rule = [
        {
          match.namespace = "waybar";
          blur = true;
        }
        {
          match.namespace = "swaync-control-center";
          blur = true;
        }
        {
          match.namespace = "swaync-notification-window";
          blur = true;
        }
        {
          match.namespace = "vicinae";
          blur = true;
        }
        {
          match.namespace = "waybar";
          ignore_alpha = 0.01;
        }
        {
          match.namespace = "swaync-control-center";
          ignore_alpha = 0;
        }
        {
          match.namespace = "swaync-notification-window";
          ignore_alpha = 0;
        }
        {
          match.namespace = "vicinae";
          ignore_alpha = 0;
        }
        {
          match.namespace = "swaync-control-center";
          animation = "slide top";
        }
      ];

      window_rule = [
        # Pavucontrol
        {
          match.class = "(.*org.pulseaudio.pavucontrol.*)";
          float = true;
          pin = true;
          center = true;
        }
        {
          match.class = "(.*org.pulseaudio.pavucontrol.*)";
          size = "700 600";
        }
        {
          match.class = "(.*org.pulseaudio.pavucontrol.*)";
          animation = "slide top";
        }

        # Satty
        {
          match.class = "(.*satty.*)";
          float = true;
          pin = true;
          center = true;
        }
        {
          match.class = "(.*satty.*)";
          size = "900 700";
        }

        # Blueman Manager
        {
          match.title = "(Bluetooth Devices)";
          float = true;
          center = true;
        }
        {
          match.title = "(Bluetooth Devices)";
          size = "800 600";
        }
        {
          match.title = "(Bluetooth Devices)";
          animation = "slide top";
        }

        # nwg-look
        {
          match.class = "(nwg-look)";
          float = true;
          center = true;
        }
        {
          match.class = "(nwg-look)";
          size = "700 600";
        }

        # nwg-displays
        {
          match.class = "(nwg-displays)";
          float = true;
          center = true;
        }
        {
          match.class = "(nwg-displays)";
          size = "900 600";
        }

        # Gnome Calculator
        {
          match.class = "(org.gnome.Calculator)";
          float = true;
          center = true;
        }
        {
          match.class = "(org.gnome.Calculator)";
          size = "700 600";
        }

        # Hyprland Share Picker
        {
          match.class = "(hyprland-share-picker)";
          float = true;
          pin = true;
          center = true;
        }
        {
          match.class = "(hyprland-share-picker)";
          size = "600 400";
        }

        # nm-connection-editor
        {
          match.class = "(nm-connection-editor)";
          float = true;
          center = true;
        }
        {
          match.class = "(nm-connection-editor)";
          size = "800 700";
        }
        {
          match.class = "(nm-connection-editor)";
          animation = "slide top";
        }

        # Picture-in-Picture
        {
          match.title = "(Picture-in-Picture)";
          float = true;
          center = true;
          pin = true;
        }

        # Steam
        {
          match.class = "^(steam)$";
          float = true;
        }
        {
          match = {
            class = "^(steam)$";
            title = "^(Steam)$";
          };
          tile = true;
        }
        {
          match = {
            class = "^(steam)$";
            title = ".*Big Picture.*";
          };
          workspace = "10";
        }
        {
          match = {
            class = "^(steam)$";
            title = ".*Big Picture.*";
          };
          fullscreen = true;
        }

        # Vesktop
        {
          match.class = "(vesktop)";
          opaque = true;
        }

        # Bitwarden
        {
          match.title = ".*Bitwarden Password Manager.*";
          float = true;
        }

        # Calendar
        {
          match.class = "(org.gnome.Calendar)";
          float = true;
        }
        {
          match.class = "(org.gnome.Calendar)";
          size = "400 600";
        }
        {
          match.class = "(org.gnome.Calendar)";
          move = "3020 70";
        }
        {
          match.class = "(org.gnome.Calendar)";
          animation = "slide top";
        }
      ];
    };

    extraConfig = ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
        hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
        hl.exec_cmd("swaync")
        hl.exec_cmd("swaybg -i ${config.stylix.image} -m fill")
        hl.exec_cmd("waybar")
        hl.exec_cmd("wl-paste --watch cliphist store")
      end)
    '';
  };

  home.packages = with pkgs; [
    # === Hyprland ecosystem ===
    swaybg
    xdg-desktop-portal-hyprland

    # === Notifications ===
    swaynotificationcenter
    libnotify

    # === Clipboard ===
    cliphist
    wl-clipboard

    # === Authentication ===
    polkit_gnome

    # === System controls ===
    brightnessctl
    playerctl
    wireplumber
    pulseaudio
    pavucontrol
    psmisc

    # === Screenshots ===
    grim
    slurp
    swappy
    satty

    # === Wallpaper ===
    waypaper

    # === Settings ===
    nwg-look
    nwg-displays

    # === Waybar ===
    waybar
    font-awesome

    # === Rofi ===
    rofi

    # === Qt theming - runtime plugins (stylix generates the Base16Kvantum theme) ===
    libsForQt5.qt5ct
    kdePackages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum

    # === Fonts ===
    fira
    inter
    fira-code
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    wev
  ];
}
