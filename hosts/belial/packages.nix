{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nix-init
    pkgs.glib
    pkgs.gsettings-desktop-schemas
  ];
}
