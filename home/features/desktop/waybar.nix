{pkgs, ...}:
let
  colors = import ./colors.nix;
in
{
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        output = "Virtual-1";
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
          "hyprland/language"
          "pulseaudio"
          "bluetooth"
          "network"
          "tray"
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
          format = "Apps";
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
        };

        network = {
          format = "{ifname}";
          format-wifi = "󰖩 {essid} ({signalStrength}%)";
          format-ethernet = "󰈀 {ifname}";
          format-disconnected = "󰖪 Disconnected";
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-wifi = "{ifname} @ {essid}\nIP: {ipaddr}\nStrength: {signalStrength}%\nFreq: {frequency}MHz\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
          tooltip-format-ethernet = "{ifname}\nIP: {ipaddr}\nUp: {bandwidthUpBits} Down: {bandwidthDownBits}";
          tooltip-format-disconnected = "Disconnected";
          max-length = 50;
          on-click = "nm-connection-editor";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = "󰝟 {icon} {format_source}";
          format-muted = "󰝟 {format_source}";
          format-source = "{volume}% 󰍬";
          format-source-muted = "󰍭";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋋";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰏲";
            car = "󰄋";
            default = ["󰕿" "󰖀" "󰕾"];
          };
          on-click = "pavucontrol";
        };

        bluetooth = {
          format = "󰂯 {status}";
          format-disabled = "";
          format-off = "";
          interval = 30;
          on-click = "blueman-manager";
          format-no-controller = "";
        };
      }
      {
        layer = "top";
        output = "DP-3";
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

        "custom/exit" = {
          format = "󰐥";
          on-click = "wlogout-launcher";
          on-click-right = "hyprlock";
          tooltip-format = "Left: Power menu\nRight: Lock screen";
        };

        clock = {
          format = "{:%H:%M}";
          tooltip = false;
        };
      }
    ];

    style = ''
      /* Colors - shared theme */
      @define-color blur_background ${colors.backgroundTransparent};
      @define-color backgroundlight ${colors.foreground};
      @define-color backgrounddark ${colors.backgroundDark};
      @define-color workspacesbackground1 ${colors.foreground};
      @define-color workspacesbackground2 ${colors.backgroundDark};
      @define-color bordercolor ${colors.foreground};
      @define-color textcolor1 ${colors.foreground};
      @define-color textcolor2 ${colors.backgroundDark};
      @define-color textcolor3 ${colors.foreground};
      @define-color iconcolor ${colors.foreground};

      /* General */
      * {
        font-family: "Fira Sans Semibold", "Font Awesome 6 Free", "Font Awesome 6 Brands", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
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
        font-size: 16px;
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
        color: @textcolor1;
        background: @workspacesbackground2;
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
        font-size: 16px;
        font-weight: normal;
        opacity: 0.8;
      }

      window#waybar.empty #window {
        background-color: transparent;
      }

      /* Custom Appmenu */
      #custom-appmenu {
        background-color: @backgrounddark;
        font-size: 16px;
        color: @textcolor1;
        border-radius: 15px;
        padding: 0px 10px 0px 10px;
        margin: 8px 16px 8px 0px;
        opacity: 0.8;
        border: 3px solid @bordercolor;
      }

      /* Custom Notification */
      #custom-notification {
        margin: 0px 13px 0px 0px;
        padding: 0px;
        font-size: 20px;
        color: @iconcolor;
        opacity: 0.8;
      }

      /* Custom Exit */
      #custom-exit {
        margin: 0px 13px 0px 0px;
        padding: 0px;
        font-size: 20px;
        color: @iconcolor;
        opacity: 0.8;
      }

      /* Language */
      #language {
        background-color: @backgroundlight;
        font-size: 16px;
        color: @textcolor2;
        border-radius: 15px;
        padding: 2px 10px 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
      }

      /* Clock */
      #clock {
        background-color: @backgrounddark;
        font-size: 16px;
        color: @textcolor1;
        border-radius: 15px;
        padding: 1px 10px 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
        border: 3px solid @bordercolor;
      }

      /* Pulseaudio */
      #pulseaudio {
        background-color: @backgroundlight;
        font-size: 16px;
        color: @textcolor2;
        border-radius: 15px;
        padding: 2px 10px 0px 10px;
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
        font-size: 16px;
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
        font-size: 16px;
        color: @textcolor2;
        border-radius: 15px;
        padding: 2px 10px 0px 10px;
        margin: 8px 15px 8px 0px;
        opacity: 0.8;
      }

      #bluetooth.off {
        background-color: transparent;
        padding: 0px;
        margin: 0px;
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
