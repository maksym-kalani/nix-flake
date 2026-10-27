{
  outputs,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [ outputs.overlays.zen-browser-release-pin ];

  environment.systemPackages = [ pkgs.zen-browser ];
}
