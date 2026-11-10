{ flake }:
originalConfig:
{ lib, ... }:
let
  expectedSelfTarget = {
    type = "path";
    path = flake.outPath;
  }
  // builtins.intersectAttrs {
    lastModified = null;
    rev = null;
    narHash = null;
  } flake;
in
{
  # Inspect the original config so the override cannot affect its own condition.
  nix.registry =
    lib.mkIf
      (originalConfig.nix.registry ? self && originalConfig.nix.registry.self.to == expectedSelfTarget)
      {
        self.to = lib.mkOverride 900 {
          type = "indirect";
          id = "ci-self";
        };
      };
}
