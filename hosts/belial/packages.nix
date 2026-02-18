{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nix-init
    pkgs.glib
    pkgs.gsettings-desktop-schemas
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}
