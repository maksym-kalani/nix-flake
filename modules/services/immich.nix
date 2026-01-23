{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.immich;
  name = "immich";
  port = 2283;
in {
  options.server.services.immich = {
    enable = lib.mkEnableOption "Immich photo management";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.immich = {
        enable = true;
        host = config.server.ip;
        port = port;
        mediaLocation = "/mnt/tank/media/photos/immich";
        group = "tankusers";
        openFirewall = true;
        database.enableVectors = false;
      };
    }
  ]);
}
