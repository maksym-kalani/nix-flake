{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.glib
    pkgs.gsettings-desktop-schemas
    pkgs.lmstudio
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}
