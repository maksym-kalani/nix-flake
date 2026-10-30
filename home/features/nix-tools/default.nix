{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixd
    sops
    nix-weather
    devenv
    mcp-nixos
    deadnix
  ];
}
