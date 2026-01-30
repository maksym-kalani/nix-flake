{pkgs, ...}:
let
  # Colors from your current theme
  colors = {
    background = "rgba(44, 47, 66, 0.7)";
    primary = "#b8c3ff";
    surface = "#121318";
    on-surface = "#e3e1e9";
  };

  # Wallpaper for rofi background (same as hyprland)
  wallpaper = ../hyprland/assets/wallpaper.png;

  # Generate blurred wallpaper at build time
  blurredWallpaper = pkgs.runCommand "blurred-wallpaper.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    convert ${wallpaper} -blur 0x50 -brightness-contrast -10x-10 $out
  '';
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
  };

  # Cliphist
  services.cliphist.enable = true;

  home.packages = with pkgs; [
    rofi
    wl-clipboard
  ];

  # Main rofi config
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      modi: "drun,filebrowser,window,run";
      font: "Fira Sans 11";
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
      background: ${colors.background};
      primary: ${colors.primary};
      surface: ${colors.surface};
      on-surface: ${colors.on-surface};
      border-width: 2px;
      border-radius: 2em;
      current-image: url("${blurredWallpaper}", height);
    }

    window {
      height: 35em;
      width: 56em;
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
      orientation: horizontal;
      children: [ "imagebox", "listbox" ];
      background-color: transparent;
      background-image: @current-image;
    }

    imagebox {
      padding: 20px;
      background-color: transparent;
      orientation: vertical;
      children: [ "inputbar", "dummy", "mode-switcher" ];
    }

    dummy {
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

    listbox {
      padding: 0em;
      spacing: 0em;
      orientation: horizontal;
      children: [ "listview" ];
      background-color: @background;
    }

    listview {
      padding: 1.5em;
      spacing: 0.5em;
      enabled: true;
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
      font: "Fira Sans 11";
      show-icons: false;
      hover-select: false;
      scroll-method: 1;
      me-select-entry: "";
      me-accept-entry: "MousePrimary";
    }

    * {
      background: ${colors.background};
      primary: ${colors.primary};
      surface: ${colors.surface};
      on-surface: ${colors.on-surface};
      border-width: 2px;
      border-radius: 2em;
    }

    window {
      width: 30em;
      x-offset: -2em;
      y-offset: 2em;
      spacing: 0px;
      padding: 0px;
      margin: 0px;
      border: @border-width;
      border-color: @primary;
      cursor: "default";
      transparency: "real";
      location: northeast;
      anchor: northeast;
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
