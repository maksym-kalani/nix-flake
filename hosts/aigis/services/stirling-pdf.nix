{
  lib,
  config,
  ...
}: let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  appdata = "/var/lib/containers/";
  # Configuration options with defaults
  cfg = {
    # Container name
    name = "stirling-pdf";

    # Container image
    image = "frooodle/s-pdf:latest-ultra-lite";

    # Container port configuration
    port = {
      internal = 8080; # Port inside the container
      external = 7080; # Port on the host
    };

    # Optional settings with defaults
    extraOptions = [
      # Resource constraints
      #"--memory=512m"
      #"--cpus=2"

      # Network settings
      #"--network=host"

      # Security options
      #"--cap-drop=ALL"
      #"--cap-add=NET_BIND_SERVICE"

      # Health check
      #"--health-cmd=curl -f http://localhost/ || exit 1"
      #"--health-interval=30s"

      # Labels
      #"--label=com.example.description=Web server"
    ];
    volumes = [
      # Simple host:container path mapping
      "${appdata}${cfg.name}/config:/configs:rw"
      "${appdata}${cfg.name}/logs:/logs:rw"

      # Configuration with read-only flag
      #"/config/files:/etc/nginx/conf.d:ro"

      # Named volume
      #"nginx-data:/var/www/html"

      # Bind mount with specific options
      #"/var/log/nginx:/var/log/nginx:Z"
    ];
    environmentVariables = {
      # Simple key-value pairs
      DOCKER_ENABLE_SECURITY = "false";
      SECURITY_ENABLELOGIN = "false";
      SYSTEM_DEFAULTLOCALE = "en-US";
      UI_APPNAME = "Stirling-PDF-Ultra-lite";
      UI_HOMEDESCRIPTION = "Demo site for Stirling-PDF-Ultra-lite Latest";
      UI_APPNAMENAVBAR = "Stirling-PDF-Ultra-lite Latest";
      SYSTEM_MAXFILESIZE = "1000";
      METRICS_ENABLED = "false";
      SYSTEM_GOOGLEVISIBILITY = "true";
      # Toggle features
      #ENABLE_GZIP = "true";
      #DEBUG_MODE = "false";
    };

    # Run settings
    autoStart = true;
  };
in {
  # Container definition
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];

    # Optional configs
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

  services.caddy.virtualHosts = {
    "${cfg.name}.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port.external}
      '';
    };
  };
}
