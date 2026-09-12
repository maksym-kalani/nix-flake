{
  config,
  ...
}: let
  ip = "192.168.2.50";
  domain = "laufin.xyz";
  appdata = "/var/lib/containers/";
  cfg = {
    name = "trek";

    image = "mauriceboe/trek:latest";

    port = {
      internal = 3000;
      external = 3000;
    };

    # Hardening mirrored from the upstream docker-compose.yml
    extraOptions = [
      "--read-only"
      "--security-opt=no-new-privileges"
      "--cap-drop=ALL"
      "--cap-add=CHOWN"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
      "--tmpfs=/tmp:noexec,nosuid,size=128m"
    ];
    volumes = [
      "${appdata}${cfg.name}/data:/app/data"
      "${appdata}${cfg.name}/uploads:/app/uploads"
    ];
    environmentVariables = {
      NODE_ENV = "production";
      PORT = "${toString cfg.port.internal}";
      TZ = "Europe/Kyiv";
      LOG_LEVEL = "info";
      APP_URL = "https://${cfg.name}.${domain}";
      ALLOWED_ORIGINS = "https://${cfg.name}.${domain}";
      # Caddy terminates TLS in front of this container
      TRUST_PROXY = "1";
    };

    autoStart = true;
  };
in {
  # ENCRYPTION_KEY secures data at rest; rotating it makes existing data unreadable
  sops.templates."trek-env".content = ''
    ENCRYPTION_KEY=${config.sops.placeholder.trek_encryption_key}
  '';

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
    environmentFiles = [config.sops.templates."trek-env".path];
  };

  networking.firewall.allowedTCPPorts = [cfg.port.external];

  services.gatus.settings.endpoints = [
    {
      name = cfg.name;
      url = "http://${ip}:${toString cfg.port.external}/api/health";
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
