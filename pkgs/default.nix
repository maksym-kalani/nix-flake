{ pkgs, ... }:
let
  harness = import ./pi-harness { inherit pkgs; };
in
{
  kenku-fm = pkgs.callPackage ./kenku-fm { };

  pi-harness = harness.package;
  pi-runtime = harness.runtime;
  pi-addons = harness.runtime; # one locked Node tree; shared Pi peers, no duplicate core
  pi-skills = harness.skills;
  pi-sandbox-acceptance = pkgs.writeShellScriptBin "pi-sandbox-acceptance" ''
    exec ${pkgs.python3}/bin/python3 ${../tests/pi/sandbox_acceptance.py} ${harness.package}/bin/pi
  '';
}
