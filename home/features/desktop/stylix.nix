{ pkgs, ... }:
{
  # Core stylix settings (enable, image, polarity, fonts, cursor) are configured
  # at the NixOS level in hosts/belial/stylix.nix and inherited automatically.

  gtk.iconTheme = {
    name = "Colloid";
    package = pkgs.colloid-icon-theme;
  };

  stylix = {
    # Disable targets we configure manually with custom CSS/structure
    targets.swaync.enable = false;
    # Qt doesn't auto-enable for standalone Home Manager — set it explicitly
    targets.qt.enable = true;
    # Waybar: let stylix inject @base0X CSS vars, but skip the opinionated default rules
    targets.waybar.addCss = false;
  };
}
