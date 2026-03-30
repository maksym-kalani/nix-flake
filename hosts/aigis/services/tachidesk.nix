{
  lib,
  ...
}: let
  ip = "192.168.2.50";
  appdata = "/var/lib/containers/";
  cfg = {
    name = "tachidesk";

    image = "ghcr.io/suwayomi/tachidesk:stable";

    port = {
      internal = 4567;
      external = 4568;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}/downloads:/home/suwayomi/.local/share/Tachidesk/downloads"
      "${appdata}${cfg.name}/:/home/suwayomi/.local/share/Tachidesk"

    ];
    environmentVariables = {
      TZ = "Europe/Kyiv";
      FLARESOLVERR_ENABLED = "true";
      FLARESOLVERR_URL = "https://flaresolverr.laufin.xyz";
      DOWNLOAD_AS_CBZ = "true";

    };

    autoStart = true;
  };
in {
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };

  networking.firewall.allowedTCPPorts = [cfg.port.external];

  services.gatus.settings.endpoints = [
    {
      name = cfg.name;
      url = "http://${ip}:${toString cfg.port.external}";
      interval = "1m";
      conditions = [
        "[STATUS] == 401"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${cfg.name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
