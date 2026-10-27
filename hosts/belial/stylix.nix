{
  imports = [ ./stylix-theme.nix ];

  stylix = {
    targets.console.enable = false;
    targets.kmscon.enable = false;
  };
}
