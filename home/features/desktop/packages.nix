# All packages for the desktop environment
# Consolidated from hyprland, waybar, rofi, wlogout, and theming modules
{ pkgs, ... }:
let
  # Wlogout launcher script with dynamic margins based on monitor
  wlogoutScript = pkgs.writeShellScriptBin "wlogout-launcher" ''
    res_w=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq '.[] | select(.focused==true) | .width')
    res_h=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq '.[] | select(.focused==true) | .height')
    h_scale=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')
    w_margin=$((res_h * 27 / h_scale))
    wlogout -b 5 -T $w_margin -B $w_margin
  '';
in
{
  home.packages = with pkgs; [
    # === Hyprland ecosystem ===
    hyprlock
    hypridle
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

    # === Screenshots ===
    grim
    slurp
    swappy

    # === Wallpaper ===
    waypaper

    # === Settings ===
    nwg-look
    nwg-displays

    # === Cursor theme ===
    bibata-cursors

    # === Waybar ===
    waybar
    font-awesome

    # === Rofi ===
    rofi

    # === Wlogout ===
    wlogoutScript

    # === Qt theming ===
    libsForQt5.qt5ct
    kdePackages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum

    # === Fonts ===
    fira
    fira-sans
    fira-code
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];
}
