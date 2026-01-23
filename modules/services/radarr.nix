{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.radarr;
  name = "radarr";
  port = 7878;
in {
  options.server.services.radarr = {
    enable = lib.mkEnableOption "Radarr movie manager";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.radarr = {
        enable = true;
        openFirewall = true;
      };
      users.users.radarr.extraGroups = [ "tankusers" ];
    }
  ]);
}
