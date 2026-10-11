{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.piHarness;
  harness = import ../../../pkgs/pi-harness {
    inherit pkgs;
    inherit (cfg) includeHomeManager extraTools;
  };
in
{
  options.features.piHarness = {
    enable = lib.mkEnableOption "the sandboxed personal Pi coding harness (#239)";
    includeHomeManager = lib.mkEnableOption "the optional pinned upstream home-manager skill";
    extraTools = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Explicit project runtimes (e.g. matching .NET SDK) available inside the sandbox; no host PATH inheritance.";
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ harness.package ];
    assertions = [
      {
        assertion = !(lib.any (package: (package.pname or "") == "pi-coding-agent") config.home.packages);
        message = "Pi harness must not coexist with an unsandboxed pi-coding-agent in Home Manager PATH.";
      }
    ];
  };
}
