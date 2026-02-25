# Aigis host tests
{ pkgs, inputs, outputs }:

{
  # Tests all services (native NixOS services + Podman containers)
  services = import ./services.nix { inherit pkgs inputs outputs; };
}
