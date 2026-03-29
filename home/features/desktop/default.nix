# Desktop environment feature
# Bundles Hyprland WM with its co-dependent components:
# - waybar (status bar)
# - wlogout (power menu)
# - swaync (notification center)
#
# These components share:
# - Color scheme (stylix, generated from base16Scheme in hosts/belial/stylix.nix)
# - Wallpaper (assets/wallpaper.png via stylix.image)
# - Integration via keybindings and exec-once
#
# This feature should be enabled as a whole. Individual components
# are not designed to work independently.
{
  imports = [
    ./stylix.nix
    ./packages.nix
    ./scripts.nix
    ./hyprland.nix
    ./waybar.nix
    ./wlogout.nix
    ./swaync.nix
    ./mimeapps.nix
    ./vicinae.nix
    ./zed.nix
  ];
}
