# Belial - Gaming PC configuration
# Generate hardware-configuration.nix on the target machine with:
# sudo nixos-generate-config --dir ./hosts/belial

{
  imports = [
    ../common
    ./configuration.nix
    ./hyprland.nix
    ./zen.nix
    ./gaming.nix
  ];
}