# Belial - Gaming PC configuration
# Generate hardware-configuration.nix on the target machine with:
# sudo nixos-generate-config --dir ./hosts/belial
{
  imports = [
    ../common
    ./stylix.nix
    ./vicinae.nix
    ./configuration.nix
    ./audio.nix
    ./bluetooth.nix
    ./printing.nix
    ./shell.nix
    ./hyprland.nix
    ./zen.nix
    ./gaming.nix
    ./smb.nix
    ./packages.nix
    ./obs.nix
    ./webcam.nix
  ];
}
