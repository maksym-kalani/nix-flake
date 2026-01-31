# Desktop environment feature
# Bundles Hyprland WM with its co-dependent components:
# - waybar (status bar)
# - rofi (application launcher)
# - wlogout (power menu)
# - swaync (notification center)
#
# These components share:
# - Color scheme (colors.nix)
# - Wallpaper (assets/wallpaper.png)
# - Integration via keybindings and exec-once
#
# This feature should be enabled as a whole. Individual components
# are not designed to work independently.
{
  imports = [
    ./packages.nix
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./wlogout.nix
    ./swaync.nix
    ./theming.nix
    ./mimeapps.nix
  ];
}
