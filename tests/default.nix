# Test exports
# Usage: nix flake check
#        nix build .#checks.x86_64-linux.aigis-services
{ pkgs, inputs, outputs }:

let
  aigisTests = import ./aigis { inherit pkgs inputs outputs; };
in {
  # All aigis services (native + containers)
  aigis-services = aigisTests.services;
}
