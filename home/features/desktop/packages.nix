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
    psmisc

    # === Screenshots ===
    grim
    slurp
    swappy

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
