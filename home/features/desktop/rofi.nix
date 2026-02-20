{ pkgs, ... }:
let
  colors = import ./colors.nix;
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
  };

  # Cliphist
  services.cliphist.enable = true;

  # Main rofi config
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,filebrowser,window,run";
      font: "Inter 11";
      show-icons: true;
      display-drun: " ";
      display-run: " ";
      display-filebrowser: "";
      display-window: "";
      drun-display-format: "{name}";
      hover-select: false;
      scroll-method: 1;
      me-select-entry: "";
      me-accept-entry: "MousePrimary";
      window-format: "{w} · {c} · {t}";
    }

    * {
      background: rgba(26, 27, 46, 0.85);
      primary: ${colors.focus};
      surface: ${colors.backgroundDark};
      on-surface: ${colors.focus};
      border-width: 2px;
      border-radius: 2em;
    }

    window {
      height: 35em;
      width: 36em;
      transparency: "real";
      fullscreen: false;
      enabled: true;
      cursor: "default";
      spacing: 0em;
      padding: 0em;
      border: @border-width;
      border-color: @primary;
      border-radius: @border-radius;
      background-color: @background;
    }

    mainbox {
      enabled: true;
      spacing: 0em;
      padding: 0em;
      orientation: vertical;
      children: [ "inputbar", "listview" ];
      background-color: transparent;
    }

    mode-switcher {
      orientation: horizontal;
      width: 6.6em;
      enabled: true;
      padding: 1.5em;
      spacing: 1.5em;
      background-color: transparent;
    }

    button {
      padding: 15px;
      border-radius: 2em;
      border: 0;
      cursor: pointer;
      background-color: @background;
      text-color: @on-surface;
    }

    button selected {
      padding: 15px;
      border-radius: 2em;
      background-color: @surface;
      text-color: @on-surface;
    }

    inputbar {
      enabled: true;
      margin: 1em;
      children: [ "textbox-prompt-colon", "entry" ];
      border-radius: 2em;
      background-color: @surface;
    }

    textbox-prompt-colon {
      enabled: true;
      expand: false;
      str: "  ";
      padding: 1em 0.3em 0 0;
      text-color: @on-surface;
      background-color: transparent;
    }

    entry {
      enabled: true;
      spacing: 1em;
      padding: 1em;
      text-color: @on-surface;
      cursor: text;
      placeholder: "Search";
      background-color: transparent;
      placeholder-color: inherit;
    }

    listview {
      padding: 1.5em;
      spacing: 0.5em;
      enabled: true;
      border: 0;
      columns: 1;
      lines: 10;
      cycle: true;
      dynamic: true;
      scrollbar: false;
      layout: vertical;
      reverse: false;
      fixed-height: true;
      fixed-columns: true;
      cursor: "default";
      background-color: transparent;
      text-color: @on-surface;
    }

    element {
      enabled: true;
      spacing: 10px;
      padding: 0.5em;
      cursor: pointer;
      background-color: transparent;
      text-color: @on-surface;
    }

    element selected.normal {
      background-color: @surface;
      text-color: @on-surface;
      border-radius: 1.5em;
    }

    element normal.normal,
    element normal.urgent,
    element normal.active,
    element selected.urgent,
    element selected.active,
    element alternate.normal,
    element alternate.urgent,
    element alternate.active {
      background-color: inherit;
      text-color: @on-surface;
    }

    element-icon {
      size: 3em;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
      border-radius: 0em;
    }

    element-text {
      vertical-align: 0.5;
      horizontal-align: 0.0;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
    }

    error-message {
      text-color: @on-surface;
      background-color: @background;
      children: [ "textbox" ];
    }

    textbox {
      text-color: inherit;
      background-color: inherit;
      vertical-align: 0.5;
      horizontal-align: 0.5;
    }
  '';

  # Cliphist rofi theme
  xdg.configFile."rofi/config-cliphist.rasi".text = ''
    configuration {
      modi: "drun";
      font: "Inter 11";
      show-icons: false;
      hover-select: false;
      scroll-method: 1;
      me-select-entry: "";
      me-accept-entry: "MousePrimary";
    }

    * {
      background: rgba(26, 27, 46, 0.85);
      primary: ${colors.focus};
      surface: ${colors.backgroundDark};
      on-surface: ${colors.focus};
      border-width: 2px;
      border-radius: 2em;
    }

    window {
      width: 30em;
      spacing: 0px;
      padding: 0px;
      margin: 0px;
      border: @border-width;
      border-color: @primary;
      cursor: "default";
      transparency: "real";
      location: center;
      anchor: center;
      fullscreen: false;
      enabled: true;
      border-radius: @border-radius;
      background-color: transparent;
    }

    mainbox {
      enabled: true;
      spacing: 0em;
      padding: 0em;
      orientation: vertical;
      children: [ "inputbar", "listview" ];
      background-color: @background;
    }

    inputbar {
      enabled: true;
      spacing: 0em;
      padding: 1em;
      children: [ "textbox-prompt-colon", "entry" ];
      background-color: @surface;
      border: 0px;
    }

    textbox-prompt-colon {
      enabled: true;
      expand: false;
      str: "  ";
      padding: 0.5em 0.2em 0em 0em;
      text-color: @on-surface;
      background-color: transparent;
    }

    entry {
      enabled: true;
      spacing: 1em;
      padding: 0.5em;
      background-color: @surface;
      text-color: @on-surface;
      cursor: text;
      placeholder: "Search clipboard";
      placeholder-color: inherit;
    }

    listview {
      padding: 1em;
      spacing: 0em;
      margin: 0em;
      border: 0px;
      enabled: true;
      columns: 1;
      lines: 8;
      cycle: false;
      dynamic: true;
      scrollbar: false;
      layout: vertical;
      reverse: false;
      fixed-height: true;
      fixed-columns: true;
      cursor: "default";
      background-color: transparent;
      text-color: @on-surface;
    }

    element {
      enabled: true;
      padding: 1em;
      margin: 0em;
      cursor: pointer;
      background-color: transparent;
      text-color: @on-surface;
      border-radius: 1.1em;
    }

    element selected.normal {
      background-color: @surface;
      text-color: @on-surface;
      border-radius: 1.5em;
    }

    element normal.normal,
    element normal.active,
    element alternate.normal {
      background-color: inherit;
      text-color: @on-surface;
    }

    element-icon {
      size: 0em;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
    }

    element-text {
      vertical-align: 0.5;
      horizontal-align: 0.0;
      cursor: inherit;
      background-color: transparent;
      text-color: inherit;
    }
  '';

  # Cliphist script
  home.file.".local/bin/cliphist-rofi".source = pkgs.writeShellScript "cliphist-rofi" ''
    #!/usr/bin/env bash
    case $1 in
      d) cliphist list | rofi -dmenu -config ~/.config/rofi/config-cliphist.rasi -p "Delete" | cliphist delete ;;
      w) cliphist wipe ;;
      *) cliphist list | rofi -dmenu -config ~/.config/rofi/config-cliphist.rasi -p "Clipboard" | cliphist decode | wl-copy ;;
    esac
  '';
}
