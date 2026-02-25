{ pkgs, ... }:
let
  colors = import ./colors.nix;
in
{
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        output = "DP-1";
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
          "mpris"
          "custom/mic"
          "custom/camera"
          "hyprland/language"
          "pulseaudio"
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
          on-click = "sleep 0.2;pkill rofi || rofi -show drun -replace";
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
          format = "<span size='18pt' rise='-3pt'>{player_icon}  </span>{artist} - {title}";
          format-paused = "<span size='18pt' rise='-3pt'>{player_icon} </span> {artist} - {title}";
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
      /* Colors - shared theme */
      @define-color blur_background ${colors.backgroundTransparent};
      @define-color backgroundlight ${colors.backgroundDark};
      @define-color backgrounddark ${colors.backgroundDark};
      @define-color workspacesbackground1 ${colors.backgroundDark};
      @define-color workspacesbackground2 ${colors.backgroundDark};
      @define-color bordercolor ${colors.foreground};
      @define-color textcolor1 ${colors.focus};
      @define-color textcolor2 ${colors.focus};
      @define-color textcolor3 ${colors.focus};
      @define-color iconcolor ${colors.focus};
      @define-color focuscolor ${colors.focus};

      /* General */
      * {
        font-family: "Inter Semibold", "JetBrainsMono Nerd Font Propo", Roboto, Helvetica, Arial, sans-serif;
        border: none;
        border-radius: 0px;
      }

      window#waybar {
        background-color: @blur_background;
        border-bottom: 0px solid #ffffff;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      .modules-left {
        padding-left: 14px;
      }

      /* Workspaces */
      #workspaces {
        background: @workspacesbackground1;
        margin: 5px 1px 6px 1px;
        padding: 0px 1px;
        border-radius: 15px;
        border: 0px;
        font-weight: bold;
        font-style: normal;
        opacity: 0.8;
        font-size: 14px;
        color: @textcolor1;
      }

      #workspaces button {
        padding: 0px 5px;
        margin: 4px 3px;
        border-radius: 15px;
        border: 0px;
        color: @textcolor1;
        background-color: @workspacesbackground2;
        transition: all 0.3s ease-in-out;
        opacity: 0.4;
      }

      #workspaces button.active {
        color: @backgrounddark;
        background: @focuscolor;
        border-radius: 15px;
        min-width: 40px;
        transition: all 0.3s ease-in-out;
        opacity: 1;
      }

      #workspaces button:hover {
        color: @textcolor1;
        background: @workspacesbackground2;
        border-radius: 15px;
        opacity: 0.7;
      }

      /* Tooltips */
      tooltip {
        border-radius: 16px;
        background-color: @backgroundlight;
        opacity: 0.9;
        padding: 20px;
        margin: 0px;
      }

      tooltip label {
        color: @textcolor2;
      }

      /* Window */
      #window {
        background: @backgroundlight;
        margin: 8px 15px 8px 0px;
        padding: 2px 10px 0px 10px;
        border-radius: 12px;
        color: @textcolor2;
        font-size: 14px;
        font-weight: normal;
        opacity: 0.8;
      }

      window#waybar.empty #window {
        background-color: transparent;
      }

      /* Custom Appmenu */
      #custom-appmenu {
        background-color: transparent;
        font-size: 24px;
        color: @textcolor1;
        padding: 0px 10px 0px 14px;
        margin: 8px 16px 8px 0px;
      }

      /* Custom Notification */
      #custom-notification {
        background-color: @backgroundlight;
        font-size: 20px;
        color: @textcolor2;
        padding: 0px 10px;
        margin: 8px 0px 8px 0px;
        opacity: 0.8;
      }

      /* Custom Exit */
      #custom-exit {
        background-color: @backgroundlight;
        font-size: 20px;
        color: @textcolor2;
        border-radius: 0px 15px 15px 0px;
        padding: 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
      }

      /* Language */
      #language {
        background-color: @backgroundlight;
        font-size: 14px;
        color: @textcolor2;
        border-radius: 15px;
        padding: 2px 10px 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
      }

      /* Clock */
      #clock {
        background-color: @backgroundlight;
        font-size: 14px;
        color: @focuscolor;
        border-radius: 15px;
        padding: 1px 10px 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
        border: 2px solid @focuscolor;
      }

      /* Pulseaudio */
      #pulseaudio {
        background-color: @backgroundlight;
        font-size: 14px;
        color: @textcolor2;
        border-radius: 15px;
        padding: 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
      }

      #pulseaudio.muted {
        background-color: @backgrounddark;
        color: @textcolor1;
      }

      /* Network */
      #network {
        background-color: @backgroundlight;
        font-size: 14px;
        color: @textcolor2;
        border-radius: 15px;
        padding: 2px 10px 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
      }

      #network.ethernet {
        background-color: @backgroundlight;
        color: @textcolor2;
      }

      #network.wifi {
        background-color: @backgroundlight;
        color: @textcolor2;
      }

      /* Bluetooth */
      #bluetooth,
      #bluetooth.on,
      #bluetooth.connected {
        background-color: @backgroundlight;
        font-size: 20px;
        color: @textcolor2;
        border-radius: 15px 0px 0px 15px;
        padding: 0px 10px;
        margin: 8px 0px 8px 0px;
        opacity: 0.8;
      }

      #mpris {
        background-color: @backgroundlight;
        font-size: 14px;
        color: @textcolor2;
        border-radius: 15px;
        padding: 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
      }

      #custom-mic.active,
      #custom-camera.active {
        background: @focuscolor;
        font-size: 18px;
        color: @backgrounddark;
        border-radius: 15px;
        padding: 0px 10px;
        margin: 8px 15px 8px 0px;
      }

      #custom-mic.muted {
        background-color: alpha(#ff4444, 0.8);
        font-size: 18px;
        color: #ffffff;
        border-radius: 15px;
        padding: 0px 10px;
        margin: 8px 15px 8px 0px;
      }

      #bluetooth.off {
        background-color: @backgroundlight;
        font-size: 20px;
        color: @textcolor2;
        border-radius: 15px 0px 0px 15px;
        padding: 0px 10px;
        margin: 8px 0px 8px 0px;
        opacity: 0.8;
      }

      /* Tray */
      #tray {
        padding: 0px 15px 0px 0px;
        color: @textcolor3;
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
