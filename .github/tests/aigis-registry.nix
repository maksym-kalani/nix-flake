{
  nixpkgs ? (builtins.getFlake (toString ../..)).inputs.nixpkgs.outPath,
}:
let
  lib = import (nixpkgs + "/lib");
  flake = {
    outPath = "/source/current";
    rev = "current-revision";
    lastModified = 123;
    narHash = "current-hash";
  };
  otherFlake = {
    outPath = "/source/other";
    rev = "other-revision";
  };
  evaluateWithFlake =
    currentFlake: registry:
    let
      normalizeSelf = import ../scripts/normalize-self.nix { flake = currentFlake; };
      original = lib.evalModules {
        modules = [
          (nixpkgs + "/nixos/modules/config/nix-flakes.nix")
          {
            options.nix.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            options.environment.etc = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
            };
            config.nix.registry = registry;
          }
        ];
      };
      normalized = original.extendModules {
        modules = [ (normalizeSelf original.config) ];
      };
    in
    {
      original = original.config.nix.registry;
      registry = normalized.config.nix.registry;
      fingerprint = normalized.config.environment.etc."nix/registry.json".text;
    };
  evaluate = evaluateWithFlake flake;
  generated = evaluate { self.flake = flake; };
  removed = evaluate { };
  retargetFlake = evaluate { self.flake = otherFlake; };
  retargetTo = evaluate {
    self = {
      inherit flake;
      to = {
        type = "github";
        owner = "custom";
        repo = "self";
      };
    };
  };
  oldRevision = evaluate {
    self.flake = flake // {
      outPath = "/source/old";
      rev = "old-revision";
      narHash = "old-hash";
    };
  };
  oldFlake = flake // {
    outPath = "/source/old";
    rev = "old-revision";
    narHash = "old-hash";
  };
  normalizedOld = evaluateWithFlake oldFlake { self.flake = oldFlake; };
  customMetadata = evaluate {
    self = {
      inherit flake;
      from = {
        type = "indirect";
        id = "custom-source";
      };
      exact = false;
    };
    other.flake = otherFlake;
  };
  extraTargetField = evaluate {
    self.to = {
      type = "path";
      path = flake.outPath;
      inherit (flake) rev lastModified narHash;
      dir = "subdirectory";
    };
  };
  tests = {
    testGeneratedSelfNormalizes = {
      expr = generated.registry.self.to;
      expected = {
        type = "indirect";
        id = "ci-self";
      };
    };
    testRemovedSelfStaysAbsent = {
      expr = removed.registry ? self;
      expected = false;
    };
    testRemovedSelfChangesFingerprint = {
      expr = removed.fingerprint == generated.fingerprint;
      expected = false;
    };
    testFlakeRetargetPreserved = {
      expr = retargetFlake.registry.self.to;
      expected = retargetFlake.original.self.to;
    };
    testFlakeRetargetChangesFingerprint = {
      expr = retargetFlake.fingerprint == generated.fingerprint;
      expected = false;
    };
    testToRetargetPreserved = {
      expr = retargetTo.registry.self.to;
      expected = retargetTo.original.self.to;
    };
    testToRetargetChangesFingerprint = {
      expr = retargetTo.fingerprint == generated.fingerprint;
      expected = false;
    };
    testRevisionChurnIgnored = {
      expr = normalizedOld.fingerprint;
      expected = generated.fingerprint;
    };
    testDifferentFlakeIsNotSelf = {
      expr = oldRevision.registry.self.to;
      expected = oldRevision.original.self.to;
    };
    testFromPreserved = {
      expr = customMetadata.registry.self.from;
      expected = customMetadata.original.self.from;
    };
    testExactPreserved = {
      expr = customMetadata.registry.self.exact;
      expected = false;
    };
    testOtherRegistriesPreserved = {
      expr = customMetadata.registry.other;
      expected = customMetadata.original.other;
    };
    testExtraTargetFieldPreserved = {
      expr = extraTargetField.registry.self.to;
      expected = extraTargetField.original.self.to;
    };
  };
  failures = lib.runTests tests;
in
if failures == [ ] then { passed = builtins.attrNames tests; } else throw (builtins.toJSON failures)
