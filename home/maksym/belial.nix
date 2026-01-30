{ config, ... }:

{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/zsh
    ../features/hyprland
    ../features/kitty
    #../features/theming
    ../features/waybar
    ../features/rofi
  ];
}
