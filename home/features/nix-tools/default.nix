{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixd
    sops
    nix-weather
    devenv
    inputs.nixpkgs-mcp-nixos.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos
    deadnix
  ];
}
