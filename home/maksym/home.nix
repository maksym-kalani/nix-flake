{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.username = lib.mkDefault "maksym";
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
  home.pointerCursor.enable = true;

  home.stateVersion = "24.05";

  home.sessionVariables = {
    EDITOR = "nano";
    NIX_PATH = "nixpkgs=${pkgs.path}";
  };

  programs.home-manager.enable = true;
}
