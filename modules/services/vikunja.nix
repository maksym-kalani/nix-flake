{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.vikunja;
  name = "vikunja";
  port = 1337;
in {
  options.server.services.vikunja = {
    enable = lib.mkEnableOption "Vikunja task manager";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.vikunja = {
        enable = true;
        port = port;
        frontendHostname = "todo.${config.server.domain}";
        frontendScheme = "https";
      };
    }
  ]);
}
