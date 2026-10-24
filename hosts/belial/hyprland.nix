{pkgs, ...}: {
  # Required for xdg.portal when using home-manager with useUserPackages
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG Portal configuration for Hyprland
  xdg.autostart.enable = true;
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    extraPortals = [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gtk
      # xdg-desktop-portal-hyprland is already added automatically by the
      # `programs.hyprland` module via its `portalPackage` option; listing it
      # again here spliced to a different store path and made two distinct
      # copies claim the same generated xdg-desktop-portal-hyprland.service
      # unit, breaking the `user-units` build with "File exists".
    ];
    config = {
      common = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
      hyprland = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.OpenURI" = ["gtk"];
      };
    };
  };
}
