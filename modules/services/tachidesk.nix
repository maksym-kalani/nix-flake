{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.tachidesk;
  name = "tachidesk";
  port = 4568;
in {
  options.server.services.tachidesk = {
    enable = lib.mkEnableOption "Tachidesk manga reader";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; healthCheck = "[STATUS] == 401"; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "ghcr.io/suwayomi/tachidesk:stable";
        ports = [ "${toString port}:4567" ];
        volumes = [
          "${config.server.containerData}/${name}/downloads:/home/suwayomi/.local/share/Tachidesk/downloads"
          "${config.server.containerData}/${name}/:/home/suwayomi/.local/share/Tachidesk"
        ];
        environment = {
          TZ = "Europe/Kyiv";
          FLARESOLVERR_ENABLED = "true";
          FLARESOLVERR_URL = "https://flaresolverr.${config.server.domain}";
          DOWNLOAD_AS_CBZ = "true";
        };
        autoStart = true;
      };
    }
  ]);
}
