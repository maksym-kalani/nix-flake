let
  flake = builtins.getFlake (builtins.getEnv "AIGIS_FLAKE_REF");
  normalizeSelf = import ./normalize-self.nix { inherit flake; };
  aigis = flake.nixosConfigurations.aigis.extendModules {
    modules = [ (normalizeSelf flake.nixosConfigurations.aigis.config) ];
  };
  originalTest = flake.checks.x86_64-linux.aigis-vm;
  vm = originalTest.extend {
    modules = [
      { nodes = builtins.mapAttrs (_: node: normalizeSelf node) originalTest.nodes; }
    ];
  };
in
{
  system = aigis.config.system.build.toplevel.drvPath;
  test = vm.drvPath;
}
