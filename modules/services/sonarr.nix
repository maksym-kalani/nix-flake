{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.sonarr;
  name = "sonarr";
  port = 8989;
in {
  options.server.services.sonarr = {
    enable = lib.mkEnableOption "Sonarr TV show manager";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.sonarr = {
        enable = true;
        openFirewall = true;
      };
      users.users.sonarr.extraGroups = [ "tankusers" ];
    }
  ]);
}
