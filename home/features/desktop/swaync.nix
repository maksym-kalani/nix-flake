{ config, lib, ... }:
let
  c = config.lib.stylix.colors;
in
{
  # Config file (JSON)
  xdg.configFile."swaync/config.json".text = builtins.toJSON {
    "$schema" = "/etc/xdg/swaync/configSchema.json";
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    cssPriority = "user";

    control-center-width = 450;
    control-center-height = 500;
    control-center-margin-top = 20;
    control-center-margin-bottom = 750;
    control-center-margin-right = 15;
    control-center-margin-left = 0;

    notification-window-width = 450;
    notification-icon-size = 96;
    notification-body-image-height = 200;
    notification-body-image-width = 200;
    notification-window-preferred-output = "DP-1";

    timeout = 8;
    timeout-low = 4;
    timeout-critical = 10;

    fit-to-screen = true;
    keyboard-shortcuts = true;
    image-visibility = "when-available";
    transition-time = 200;
    hide-on-clear = true;
    hide-on-action = true;
    script-fail-notify = true;

    scripts = { };

    notification-visibility = {
      example-name = {
        state = "muted";
        urgency = "Normal";
        app-name = "Spotify";
      };
    };

    widgets = [
      "backlight"
      "title"
      "notifications"
    ];

    widget-config = {
      title = {
        text = "Notifications";
        clear-all-button = true;
        button-text = "Clear";
      };
      backlight = {
        label = "󰃟";
      };
    };
  };

  xdg.configFile."swaync/style.css".text = ''
    @import "notifications.css";
    @import "control_center.css";
  '';

  xdg.configFile."swaync/colors.css".text = ''
    @define-color surface #${c.base01};
    @define-color surface_container #${c.base01};
    @define-color surface_container_high #${c.base02};
    @define-color surface_container_low #${c.base00};
    @define-color primary #${c.base0D};
    @define-color primary_container #${c.base0E};
    @define-color primary_fixed #${c.base0D};
    @define-color on_surface #${c.base07};
    @define-color on_primary #${c.base01};
    @define-color on_primary_fixed #${c.base01};
    @define-color inverse_primary #${c.base0D};
    @define-color secondary #${c.base0D};
    @define-color error_container #${c.base08};
    @define-color on_error_container #${c.base07};
  '';

  xdg.configFile."swaync/notifications.css".text = ''
    @import 'colors.css';

    /* === Derived dynamic colors === */
    @define-color base alpha(@surface, 0.3);
    @define-color surface_custom alpha(@surface_container_high, 0.3);
    @define-color hovercolor alpha(@surface_container_high, 0.5);
    @define-color activecolor @primary_container;

    @define-color buttoncolor alpha(@inverse_primary, 0.3);
    @define-color hoverbutton alpha(@inverse_primary, 0.5);
    @define-color activebutton @inverse_primary;

    @define-color bordercolor transparent;
    @define-color fontcolor @on_surface;
    @define-color text @on_surface;

    * {
      all: unset;
      color: @text;
      font-size: 1rem;
      font-weight: 900;
      font-family: "Inter", "Font Awesome 6 Free", "Font Awesome 6 Brands", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
    }

    .notification-row {
      outline: none;
      margin: 0;
      padding: 0px;
    }

    .floating-notifications.background .notification-row .notification-background {
      background: @base;
      border-radius: 12px;
      border: 1px solid transparent;
      margin: 20px 20px;
      box-shadow: inset 2px 2px 14px alpha(@on_surface, 0.15),
                  inset 0 1px 2px 0px alpha(@on_surface, 0.15),
                  inset 1px 1px 1px alpha(@on_surface, 0.15);
    }

    .floating-notifications.background
    .notification-row
    .notification-background
    .notification.critical {
      background: alpha(@error_container, 0.3);
      color: @on_error_container;
      border-radius: 12px;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      .notification-content {
      margin: 1.2rem;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > * {
      min-height: 2.4em;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action {
      border-radius: 8px;
      background-color: alpha(@surface, 0.3);
      margin: 0.4rem;
      border: 1px solid transparent;
      box-shadow: inset 1px 1px 4px alpha(@on_surface, 0.1);
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:hover {
      background-color: alpha(@surface_container_high, 0.5);
      border: 1px solid transparent;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:active {
      background-color: alpha(@primary, 0.3);
      color: @text;
    }

    .notification-content .image {
      margin-right: 12px;
      border-radius: 10px;
      min-width: 64px;
      min-height: 64px;
    }

    .summary {
      font-weight: 800;
      font-size: 1rem;
    }

    .body {
      font-size: 0.8rem;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button {
      background: transparent;
      border-radius: 20px;
      color: @text;
      background-color: alpha(@on_surface, 0.15);
      margin: 0px;
      padding: 4px;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button:hover {
      background-color: alpha(@primary, 0.3);
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button:active {
      background-color: alpha(@primary, 0.5);
      color: @text;
    }

    .notification.critical progress {
      background-color: @primary;
    }

    .notification.low progress,
    .notification.normal progress {
      background-color: @primary;
    }
  '';

  xdg.configFile."swaync/control_center.css".text = ''
    @import 'colors.css';

    /* === Derived dynamic colors === */
    @define-color base alpha(@surface, 0.3);
    @define-color surface_custom alpha(@surface_container_high, 0.3);
    @define-color hovercolor alpha(@surface_container_high, 0.5);
    @define-color activecolor alpha(@primary, 0.3);

    @define-color buttoncolor alpha(@inverse_primary, 0.3);
    @define-color hoverbutton alpha(@inverse_primary, 0.5);
    @define-color activebutton @inverse_primary;

    @define-color bordercolor transparent;
    @define-color fontcolor @on_surface;
    @define-color text @on_surface;

    * {
      all: unset;
      color: @text;
      font-size: 1rem;
      font-weight: 900;
      font-family: "Inter", "JetBrainsMono Nerd Font Propo", "Font Awesome 7 Free",
      "Font Awesome 7 Brands", "Font Awesome 6 Free", "Font Awesome 6 Brands",
      FontAwesome;
    }

    .control-center {
      background: @base;
      border-radius: 12px;
      border: 1px solid transparent;
      padding: 8px 8px 0 8px;
      box-shadow: inset 2px 2px 14px alpha(@on_surface, 0.15),
                  inset 0 1px 2px 0px alpha(@on_surface, 0.15),
                  inset 1px 1px 1px alpha(@on_surface, 0.15);
    }

    .widget-backlight {
      padding: 12px 16px;
      margin: 0px 12px 12px 12px;
      border-radius: 8px;
      background: @surface_custom;
      box-shadow: inset 1px 1px 4px alpha(@on_surface, 0.1);
    }

    .widget-backlight trough {
      background: alpha(@surface_container_low, 0.3);
      margin: 8px 8px;
      border: 3px;
    }

    .widget-backlight trough highlight {
      background: alpha(@primary, 0.5);
      border: 2px solid alpha(@primary, 0.5);
      border-radius: 5px;
    }

    .widget-title {
      font-size: 1.5rem;
      margin: 0 12px 5px 12px;
    }

    .widget-title button {
      background: alpha(@surface_container, 0.3);
      border-radius: 8px;
      padding: 4px 16px;
      box-shadow: inset 1px 1px 4px alpha(@on_surface, 0.1);
    }

    .widget-title button:hover {
      background: @hovercolor;
    }

    .widget-dnd {
      margin: 5px 12px 0px 12px;
    }

    .widget-dnd > switch {
      color: @text;
      background: @buttoncolor;
      border-radius: 5px;
      box-shadow: none;
    }

    .widget-dnd > switch:hover {
      background: @hovercolor;
    }

    .widget-dnd > switch:checked {
      background: @buttoncolor;
      color: @on_primary;
    }

    .widget-dnd > switch slider {
      background: alpha(@secondary, 0.5);
      border-radius: 5px;
      border: 2px solid @buttoncolor;
    }

    .widget-dnd > switch:checked slider {
      background: alpha(@inverse_primary, 0.7);
    }

    .control-center .notification-row .notification-background {
      background-color: alpha(@surface_container, 0.3);
      border-radius: 12px;
      margin: 5px 0px;
      padding: 15px;
      border: 1px solid transparent;
      min-height: 2.5em;
      box-shadow: inset 1px 1px 4px alpha(@on_surface, 0.1);
    }

    .control-center .notification-row .notification-background .notification.critical {
      background-color: alpha(@error_container, 0.3);
      color: @on_error_container;
      border-radius: 12px;
    }

    .control-center .notification-row .notification-background .close-button {
      background-color: alpha(@on_surface, 0.15);
      border-radius: 5px;
      color: @text;
      padding: 5px;
    }

    .control-center .notification-row .notification-background .close-button:hover {
      background-color: alpha(@primary, 0.3);
    }

    trough highlight {
      background: alpha(@primary, 0.5);
      border: 2px solid alpha(@primary_fixed, 0.5);
      border-radius: 20px;
    }

    .notification-group {
      margin: 4px 12px 4px 12px;
    }

    .notification-group-headers {
      font-weight: 900;
      font-size: 0;
    }

    .notification-group-icon {
      padding: 0px;
    }

    .notification-group-collapse-button,
    .notification-group-close-all-button {
      background: alpha(@surface_container, 0.3);
      border-radius: 5px;
      padding: 5px;
    }

    .notification-group-collapse-button:hover,
    .notification-group-close-all-button:hover {
      background: @hovercolor;
    }
  '';
}
