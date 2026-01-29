{ config, ... }:

{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/hyprland
  ];
}
