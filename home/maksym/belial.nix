{ config, pkgs, ... }:

{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/zsh
    ../features/kitty
    ../features/theming
    ../features/desktop  # Bundles hyprland, waybar, rofi, wlogout
  ];
  
  home.packages = with pkgs; [
    zed-editor
    spotify
    vesktop
    telegram-desktop
    jellyfin-desktop
    obsidian
    jetbrains-toolbox
    obs-studio
    chromium
    audacity
    bitwarden-desktop
    blueman
    rofi-network-manager
    caligula
    #wonderdraft
    nautilus
    libreoffice-fresh
    solaar
    vlc
    mission-center
    element-desktop
    papers
  ];
}
