{ pkgs, ... }:
let
  colors = import ./colors.nix;
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
    control-center-height = 560;
    control-center-margin-top = 13;
    control-center-margin-bottom = 13;
    control-center-margin-right = 14;
    control-center-margin-left = 0;

    notification-window-width = 450;
    notification-icon-size = 96;
    notification-body-image-height = 200;
    notification-body-image-width = 400;

    timeout = 4;
    timeout-low = 2;
    timeout-critical = 6;

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
      "dnd"
      "backlight"
      "mpris"
      "title"
      "notifications"
    ];

    widget-config = {
      dnd = {
        text = "Do not Disturb";
      };
      title = {
        text = "Notifications";
        clear-all-button = true;
        button-text = "Clear";
      };
      mpris = {
        image-size = 0;
        image-radius = 0;
      };
      backlight = {
        label = "󰃟";
      };
    };
  };

  # Main style file - imports the other two
  xdg.configFile."swaync/style.css".text = ''
    @import "notifications.css";
    @import "control_center.css";
  '';

  # Colors file
  xdg.configFile."swaync/colors.css".text = ''
    @define-color surface ${colors.surface};
    @define-color surface_container ${colors.surfaceContainer};
    @define-color surface_container_high ${colors.surfaceContainerHigh};
    @define-color surface_container_low ${colors.surfaceContainerLow};
    @define-color primary ${colors.primary};
    @define-color primary_container ${colors.primaryContainer};
    @define-color primary_fixed ${colors.primaryFixed};
    @define-color on_surface ${colors.onSurface};
    @define-color on_primary ${colors.onPrimary};
    @define-color on_primary_fixed ${colors.onPrimaryFixed};
    @define-color inverse_primary ${colors.inversePrimary};
    @define-color secondary ${colors.secondary};
    @define-color error_container ${colors.errorContainer};
    @define-color on_error_container ${colors.onErrorContainer};
  '';

  # Notifications CSS (floating notifications)
  xdg.configFile."swaync/notifications.css".text = ''
    @import 'colors.css';

    /* === Derived dynamic colors === */
    @define-color base alpha(@surface, 0.5);
    @define-color surface_custom alpha(@surface_container_high,0.8);
    @define-color hovercolor alpha(@surface_container_high,0.8);
    @define-color activecolor @primary_container;

    @define-color buttoncolor alpha(@inverse_primary,0.3);
    @define-color hoverbutton alpha(@inverse_primary,0.5);
    @define-color activebutton @inverse_primary;

    @define-color bordercolor @primary;
    @define-color fontcolor @on_surface;
    @define-color text @on_surface;


    * {
      color: @text;
      font-size: 2rem;
      font-weight: 900;
      all: unset;
      font-family: "Fira Sans Semibold", "Font Awesome 6 Free", "Font Awesome 6 Brands", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
      transition: 200ms;
    }

    .widget-mpris {
      all: unset;
    }

    .notification-row {
      outline: none;
      margin: 0;
      padding: 0px;
    }

    .floating-notifications.background .notification-row .notification-background {
      background: @base;
      border-radius: 10px;
      border: 2px solid @primary;
      margin: 5px 10px;
    }

    /* Critical floating notifications */
    .floating-notifications.background
    .notification-row
    .notification-background
    .notification.critical {
      background: alpha(@error_container, 0.85);
      color: @on_error_container;
      border-radius: 10px;
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
      border-radius: 0.5rem;
      background-color: alpha(@surface, 0.95);
      margin: 0.4rem;
      border: 1px solid transparent;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:hover {
      background-color: @hovercolor;
      border: 1px solid @primary;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .notification
      > *:last-child
      > *
      .notification-action:active {
      background-color: @primary;
      color: @text;
    }

    .notification-content .image {
      margin-right: 12px;
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
      background-color: alpha(#fff, 0.5);
      margin: 0px;
      padding: 4px;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button:hover {
      background-color: @primary;
    }

    .floating-notifications.background
      .notification-row
      .notification-background
      .close-button:active {
      background-color: @primary;
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

  # Control Center CSS
  xdg.configFile."swaync/control_center.css".text = ''
    @import 'colors.css';

    /* === Derived dynamic colors === */
    @define-color base alpha(@surface, 0.5);
    @define-color surface_custom alpha(@surface_container_high,0.8);
    @define-color hovercolor alpha(@surface_container_high,0.8);
    @define-color activecolor @primary_container;

    @define-color buttoncolor alpha(@inverse_primary,0.3);
    @define-color hoverbutton alpha(@inverse_primary,0.5);
    @define-color activebutton @inverse_primary;

    @define-color bordercolor @primary;
    @define-color fontcolor @on_surface;
    @define-color text @on_surface;

    /* === Global Reset === */
    * {
      color: @text;
      font-size: 1rem;
      font-weight: 900;
      font-family: "Fira Sans Semibold", "Symbols Nerd Font", "Font Awesome 7 Free",
      "Font Awesome 7 Brands", "Font Awesome 6 Free", "Font Awesome 6 Brands",
      FontAwesome;
      transition: 200ms;
    }

    /* === Control Center Container === */
    .control-center {
      background: @base;
      border-radius: 10px;
      border: 2px solid @bordercolor;
      padding: 8px 8px 0 8px;
    }

    /* === Brightness === */
    .widget-backlight {
      padding: 12px 16px;
      margin: 0px 12px 12px 12px;
      border-radius: 8px;
      background: @surface_custom;
    }

    .widget-backlight trough {
      background: @surface_container_low;
      margin: 8px 8px;
      border: 3px;
    }

    .widget-backlight trough highlight {
      background: @primary;
      border: 2px solid @primary;
      border-radius: 5px;
    }

    /* === Music Player === */
    .widget-mpris {
      border-radius: 10px;
      margin: 2px 12px 12px 12px;
      align-items: center;
      color: alpha(#000000, 0.8);
    }

    .widget-mpris button {
      background: @surface_custom;
      border-radius: 20px;
      padding: 4px;
      margin: 20px 2px;
      color: alpha(#000000, 0.8);
    }

    .widget-mpris button:hover {
      background: @hovercolor;
    }

    .widget-mpris-player {
      border-radius: 10px;
      position: absolute;
      inset: 0;
      z-index: 0;
      overflow: hidden;
      color: alpha(#000000, 0.8);
    }

    .widget-mpris-album-art {
      border-radius: 1000px;
      margin: 8px 0 0 8px;
    }

    .widget-mpris-title {
      font-weight: 900;
      font-size: 2em;
      margin: 10px 20px 0 0;
      color: alpha(white, 0.9);
      background-color: alpha(black, 0.6);
    }

    .widget-mpris-subtitle {
      font-weight: 900;
      font-size: 0.8rem;
      margin: 0px 20px 5px 0px;
      color: alpha(white, 0.9);
      background-color: alpha(black, 0.6);
    }

    /* === Notification Clear Button === */
    .widget-title {
      font-size: 1.5rem;
      margin: 0 12px 5px 12px;
    }

    .widget-title button {
      background: @surface_container;
      border-radius: 8px;
      padding: 4px 16px;
    }

    .widget-title button:hover {
      background: @hovercolor;
    }

    /* === Do Not Disturb === */
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
      background: @secondary;
      border-radius: 5px;
      border: 2px solid @buttoncolor;
    }

    .widget-dnd > switch:checked slider {
      background: @inverse_primary;
    }

    /* === Notifications === */
    .control-center .notification-row .notification-background {
      background-color: @surface_container;
      border-radius: 10px;
      margin: 5px 0px;
      padding: 15px;
      border: 2px solid @bordercolor;
      min-height: 2.5em;
    }

    .control-center .notification-row .notification-background .notification.critical {
      background-color: @error_container;
      color: @on_error_container;
      border-radius: 10px;
    }

    .control-center .notification-row .notification-background .close-button {
      background-color: @hoverbutton;
      border-radius: 5px;
      color: @text;
      padding: 5px;
    }

    .control-center .notification-row .notification-background .close-button:hover {
      background-color: @activecolor;
    }

    /* === Progress Bars === */
    trough highlight {
      background: @primary;
      border: 2px solid @primary_fixed;
      border-radius: 20px;
    }

    /* === Notification Groups === */
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
      background: @surface_container;
      border-radius: 5px;
      padding: 5px;
    }

    .notification-group-collapse-button:hover,
    .notification-group-close-all-button:hover {
      background: @hovercolor;
    }
  '';
}
