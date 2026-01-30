# All packages for the desktop environment
# Consolidated from hyprland, waybar, rofi, and theming modules
{ pkgs, ... }:
{
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
