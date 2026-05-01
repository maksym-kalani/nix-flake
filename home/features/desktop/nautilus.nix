{ pkgs, ... }:
{
  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-sort-order = "mtime";
      default-sort-in-reverse-order = true;
    };
  };

  home.packages = with pkgs; [
    nautilus
  ];
}
