{
  ...
}: let
  ip = "192.168.2.50";
  appdata = "/var/lib/containers/";
  cfg = {
    name = "stirling-pdf";

    image = "frooodle/s-pdf:latest-ultra-lite";

    port = {
      internal = 8080;
      external = 7080;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}/config:/configs:rw"
      "${appdata}${cfg.name}/logs:/logs:rw"

    ];
    environmentVariables = {
      DOCKER_ENABLE_SECURITY = "false";
      SECURITY_ENABLELOGIN = "false";
      SYSTEM_DEFAULTLOCALE = "en-US";
      UI_APPNAME = "Stirling-PDF-Ultra-lite";
      UI_HOMEDESCRIPTION = "Demo site for Stirling-PDF-Ultra-lite Latest";
      UI_APPNAMENAVBAR = "Stirling-PDF-Ultra-lite Latest";
      SYSTEM_MAXFILESIZE = "1000";
      METRICS_ENABLED = "false";
      SYSTEM_GOOGLEVISIBILITY = "true";
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
