{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nix-init
  ];
}
