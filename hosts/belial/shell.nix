{ pkgs, ... }:

{
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Required for xdg.portal when using home-manager with useUserPackages
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
  environment.interactiveShellInit = ''
    alias rebuild='sudo nixos-rebuild switch --flake .#belial'
  '';
}
