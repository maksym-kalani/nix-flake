{ config, pkgs, ... }:

{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/zsh
    ../features/hyprland
    ../features/kitty
    ../features/theming
    ../features/waybar
    ../features/rofi
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
    wonderdraft
  ];
}
