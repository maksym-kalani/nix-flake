{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixd
    sops
    nix-weather
    devenv
    stable.mcp-nixos
    deadnix
  ];
}
