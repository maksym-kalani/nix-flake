{
  lib,
  config,
  ...
}: let
  ip = "192.168.2.50";
  appdata = "/var/lib/containers/";
  cfg = {
    name = "kavita";

    image = "jvmilazz0/kavita:latest";

    port = {
      internal = 5000;
      external = 5000;
    };

    extraOptions = [];
    volumes = [
      "/mnt/tank/media/ttrpgs:/ttrpgs"
      "${appdata}${cfg.name}:/kavita/config"

    ];
    environmentVariables = {};

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
        "[STATUS] == 200"
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
