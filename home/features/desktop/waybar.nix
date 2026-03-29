{ pkgs, ... }:
{
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        output = "!DP-2";
        margin-top = 0;
        margin-bottom = 0;
        margin-left = 0;
        margin-right = 0;
        spacing = 0;

        modules-left = [
          "custom/appmenu"
          "hyprland/workspaces"
        ];

        modules-center = [
          "hyprland/window"
        ];

        modules-right = [
          "custom/mic"
          "custom/camera"
          "mpris"
          "pulseaudio"
          "hyprland/language"
          "tray"
          "bluetooth"
          "custom/notification"
          "custom/exit"
          "clock"
        ];

        "hyprland/workspaces" = {
          on-scroll-up = "hyprctl dispatch workspace r-1";
          on-scroll-down = "hyprctl dispatch workspace r+1";
          on-click = "activate";
          active-only = false;
          all-outputs = true;
          expand = true;
          format = "{id} ➡ {windows}";
          workspace-taskbar = {
            enable = true;
            update-active-window = true;
            format = "{icon}";
            icon-size = 25;
          };
          format-icons = {
            urgent = "";
            active = "";
            default = "";
          };
          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          max-length = 60;
          separate-outputs = true;
        };

        "hyprland/language" = {
          format = "{}";
          format-uk = "UA";
          format-en = "US";
        };

        "custom/appmenu" = {
          format = "󱄅";
          on-click = "vicinae toggle";
          tooltip-format = "Open the application launcher";
        };

        "custom/exit" = {
          format = "󰐥";
          on-click = "wlogout-launcher";
          on-click-right = "hyprlock";
          tooltip-format = "Left: Power menu\nRight: Lock screen";
        };

        "custom/notification" = {
          tooltip-format = "Left: Notifications\nRight: Do not disturb";
          format = "{icon}";
          format-icons = {
            notification = "󰂚";
            none = "󰂜";
            dnd-notification = "󰂛";
            dnd-none = "󰂛";
            inhibited-notification = "󰂚";
            inhibited-none = "󰂜";
            dnd-inhibited-notification = "󰂛";
            dnd-inhibited-none = "󰂛";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };

        tray = {
          icon-size = 21;
          spacing = 10;
        };

        clock = {
          format = "{:%H:%M - %a %d.%m.%Y}";
          tooltip = false;
          on-click = "gnome-calendar";
        };

        network = {
          format = "{ifname}";
          format-wifi = "󰖩 {essid} ({signalStrength}%)";
          format-ethernet = "󰈀 {ifname}";
          format-disconnected = "󰖪 Disconnected";
          tooltip-format = "{ifname} via {gwaddr}";
          on-click = "nm-connection-editor";
          tooltip-format-wifi = "{ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
          tooltip-format-ethernet = "{ifname}\nIP: {ipaddr}\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
          tooltip-format-disconnected = "Disconnected";
          max-length = 50;
        };

        pulseaudio = {
          format = "<span size='18pt' rise='-3pt'>{icon}</span> {volume}%";
          format-bluetooth = "{volume}% <span size='18pt' rise='-3pt'>{icon}</span> {format_source}";
          format-bluetooth-muted = "<span size='18pt' rise='-3pt'>󰝟</span> <span size='18pt' rise='-3pt'>{icon}</span> {format_source}";
          format-muted = "<span size='18pt' rise='-3pt'>󰝟</span> {format_source}";
          format-source = "{volume}% <span size='18pt' rise='-3pt'>󰍬</span>";
          format-source-muted = "<span size='18pt' rise='-3pt'>󰍭</span>";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋋";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰏲";
            car = "󰄋";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
        };

        bluetooth = {
          format = "󰂯";
          format-disabled = "";
          format-off = "";
          interval = 30;
          on-click = "blueman-manager";
          format-no-controller = "";
        };

        "custom/mic" = {
          format = "{}";
          return-type = "json";
          interval = 3;
          exec = ''
            if pactl list sources short 2>/dev/null | grep -v '\.monitor' | grep -q RUNNING; then
              muted=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}')
              if [ "$muted" = "yes" ]; then
                echo '{"text": "󰍭", "tooltip": "Microphone is muted", "class": "muted"}'
              else
                echo '{"text": "󰍬", "tooltip": "Microphone is active", "class": "active"}'
              fi
            else
              echo '{"text": "", "tooltip": "", "class": ""}'
            fi
          '';
          on-click = "toggle-mute";
        };

        "custom/camera" = {
          format = "{}";
          return-type = "json";
          interval = 3;
          exec = ''
            if fuser /dev/video* 2>/dev/null | grep -q .; then
              echo '{"text": "󰄀", "tooltip": "Camera is active", "class": "active"}'
            else
              echo '{"text": "", "tooltip": "", "class": ""}'
            fi
          '';
        };

        mpris = {
          format = "<span size='18pt' rise='-3pt'> </span>{player_icon} {artist} - {title}";
          format-paused = "<span size='18pt' rise='-3pt'> </span>{player_icon} {artist} - {title}";
          player-icons = {
            spotify = "󰓇";
            mpv = "󰐊";
            firefox = "󰈹";
            chromium = "󰊯";
            default = "󰎆";
          };
          tooltip-format = "{player}\n{artist} — {title}";
          max-length = 50;
        };
      }
      {
        layer = "top";
        output = "DP-2";
        margin-top = 0;
        margin-bottom = 0;
        margin-left = 0;
        margin-right = 0;
        spacing = 0;

        modules-left = [
          "hyprland/window"
        ];

        modules-center = [
          "hyprland/workspaces"
        ];

        modules-right = [
          "clock"
        ];

        "hyprland/workspaces" = {
          on-scroll-up = "hyprctl dispatch workspace r-1";
          on-scroll-down = "hyprctl dispatch workspace r+1";
          on-click = "activate";
          active-only = false;
          all-outputs = true;
          expand = true;
          format = "{id} ➡ {windows}";
          workspace-taskbar = {
            enable = true;
            update-active-window = true;
            format = "{icon}";
            icon-size = 25;
          };
          format-icons = {
            urgent = "";
            active = "";
            default = "";
          };
          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          max-length = 60;
          separate-outputs = true;
        };

        clock = {
          format = "{:%H:%M}";
          tooltip = false;
          on-click = "gnome-calendar";
        };
      }
    ];

    style = ''
      /* Color aliases - mapped from stylix-injected @base0X vars */
      @define-color blur_background alpha(@base00, 0.3);
      @define-color backgroundlight @base01;
      @define-color backgrounddark @base01;
      @define-color workspacesbackground1 @base01;
      @define-color workspacesbackground2 @base01;
      @define-color bordercolor @base05;
      @define-color textcolor1 @base0D;
      @define-color textcolor2 @base0D;
      @define-color textcolor3 @base0D;
      @define-color iconcolor @base0D;
      @define-color focuscolor @base0D;
      @define-color surface @base00;
      @define-color primary @base0D;
      @define-color secondary @base0E;
      @define-color error @base08;
      @define-color on_error @base07;
      @define-color on_secondary @base07;
      @define-color on_surface @base05;

      /* General */
      * {
        font-family: "Inter Semibold", "JetBrainsMono Nerd Font Propo", Roboto, Helvetica, Arial, sans-serif;
        border: none;
        border-radius: 0px;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background: transparent;
        color: @textcolor1;
      }

      .modules-left {
        border-radius: 12px;
        border: 1px solid transparent;
        opacity: 0.8;
        padding: 0px;
        margin: 10px 8px 0px 20px;
        box-shadow: inset 2px 2px 14px alpha(@textcolor1, 0.15),
                    inset 0 1px 2px 0px alpha(@textcolor1, 0.15),
                    inset 1px 1px 1px alpha(@textcolor1, 0.15);
        background-color: @backgrounddark;
      }

      .modules-right {
        border-radius: 12px;
        border: 1px solid transparent;
        opacity: 0.8;
        padding: 0px;
        margin: 10px 20px 0px 8px;
        box-shadow: inset 0px 2px 14px 2px alpha(@textcolor1, 0.15),
                    inset 0 1px 2px 0px alpha(@textcolor1, 0.15),
                    inset 1px 1px 1px alpha(@textcolor1, 0.15);
        background-color: @backgrounddark;
      }

      .modules-center {
        border-radius: 12px;
        border: 1px solid transparent;
        opacity: 0.8;
        margin: 10px 8px 0px 8px;
        box-shadow: inset 2px 2px 14px alpha(@textcolor1, 0.15),
                    inset 0 1px 2px 0px alpha(@textcolor1, 0.15),
                    inset 0 1px 1px alpha(@textcolor1, 0.15);
        background-color: @backgrounddark;
      }

      label.module {
        font-size: 14px;
        margin-left: 8px;
        margin-right: 8px;
        border-radius: 5px;
      }

      /* Workspaces */
      #workspaces {
        padding: 5px 3px 5px 3px;
        min-width: 176px;
      }

      #workspaces button {
        color: @on_surface;
        border-radius: 3px;
        padding: 0px 5px 0px 5px;
        margin: 0px 2px 0px 2px;
        transition: all 0.3s ease-in-out;
        border: 1px solid transparent;
      }

      #workspaces button.active {
        background: alpha(@primary, 0.3);
        border: 1px solid transparent;
        transition: all 0.3s ease-in-out;
        min-width: 30px;
        border-radius: 8px;
        box-shadow: inset 1px 2px 2px alpha(@textcolor1, 0.2),
                    inset 0 1px 1px alpha(@textcolor1, 0.3);
      }

      #workspaces button:hover {
        background: alpha(@secondary, 0.2);
        border-radius: 15px;
      }

      /* Tooltips */
      tooltip {
        background-color: alpha(@surface, 0.7);
        border-radius: 12px;
        border: 1px solid transparent;
        opacity: 0.7;
        margin: 10px;
        box-shadow: inset 2px 2px 30px alpha(@textcolor1, 0.2),
                    inset 0 1px 2px 0px alpha(@textcolor1, 0.25),
                    inset 0 1px 1px alpha(@textcolor1, 0.25);
      }

      tooltip label {
        color: @textcolor2;
      }

      /* Window */
      #window {
        font-size: 14px;
        font-weight: normal;
        color: @textcolor2;
        padding: 0px 8px;
      }

      window#waybar.empty #window {
        background-color: transparent;
      }

      /* Taskbar */
      #taskbar {
        padding: 5px 0px 5px 0px;
      }

      #taskbar button {
        border-radius: 6px;
        padding: 0px 5px 0px 5px;
      }

      #taskbar button:hover {
        background: @primary;
        color: @backgrounddark;
      }

      /* Custom Appmenu */
      #custom-appmenu {
        font-size: 24px;
        color: @textcolor1;
        padding-right: 3px;
        padding-left: 5px;
      }

      /* Custom Notification */
      #custom-notification {
        font-size: 20px;
        color: @iconcolor;
      }

      /* Custom Exit */
      #custom-exit {
        font-size: 20px;
        color: @textcolor2;
      }

      /* Custom Updates */
      #custom-updates.yellow {
        border-radius: 8px;
        margin: 5px 0px 5px 5px;
        padding: 0px 6px 0px 6px;
        background-color: @secondary;
        color: @on_secondary;
      }

      #custom-updates.red {
        border-radius: 8px;
        margin: 6px 0px 6px 7px;
        padding: 0px 6px 0px 6px;
        background-color: @error;
        color: @on_error;
      }

      /* Hardware */
      #disk, #memory, #cpu {
        margin: 0px;
        padding: 0px;
      }

      #language {
        padding-top: 2px;
      }

      /* Clock */
      #clock {
        color: @focuscolor;
      }

      /* Pulseaudio */
      #pulseaudio {
        font-size: 14px;
        color: @textcolor2;
      }

      #pulseaudio.muted {
        color: @textcolor1;
      }

      /* Network */
      #network {
        font-size: 14px;
        color: @textcolor2;
      }

      /* Bluetooth */
      #bluetooth,
      #bluetooth.on,
      #bluetooth.connected {
        font-size: 20px;
        color: @textcolor2;
      }

      #bluetooth.off {
        font-size: 20px;
        color: @textcolor2;
      }

      /* Mpris */
      #mpris {
        font-size: 14px;
        color: @textcolor2;
        padding-left: 4px;
        padding-right: 4px;
      }

      /* Mic & Camera indicators */
      #custom-mic.active,
      #custom-camera.active {
        background: alpha(@focuscolor, 0.3);
        font-size: 18px;
        color: @focuscolor;
        border-radius: 8px;
        padding: 0px 10px;
        margin: 5px 2px;
        box-shadow: inset 1px 2px 2px alpha(@textcolor1, 0.2),
                    inset 0 1px 1px alpha(@textcolor1, 0.3);
      }

      #custom-mic.muted {
        background-color: alpha(@error, 0.3);
        font-size: 18px;
        color: @error;
        border-radius: 8px;
        padding: 0px 10px;
        margin: 5px 2px;
      }

      /* Tray */
      #tray {
        padding: 0px 5px 0px 10px;
        color: @textcolor3;
      }

      #tray.empty {
        padding: 0px;
        margin: 0px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }
    '';
  };
}
