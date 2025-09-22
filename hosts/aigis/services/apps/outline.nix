{ lib, config, pkgs, ... }:

let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  port = 3080;
  dataDir = "/mnt/tank/appdata/outline";
  cfg = config.services.outline;
in
{
  # Use the native NixOS module for Outline instead of a container
  services.outline = {
    enable = true;
    publicUrl = "https://outline.${domain}";
    port = port;

    # Use local storage on ZFS appdata
    storage = {
      storageType = "local";
      localRootDir = "${dataDir}/data";
    };

    # Use local Postgres and Redis managed by the module
    databaseUrl = "local";
    redisUrl = "local";

    # Optional: keep defaults for secretKeyFile/utilsSecretFile inside /var/lib/outline
    # You can later switch these to sops/agenix files if desired.
  };

  # Open the Outline port
  networking.firewall.allowedTCPPorts = [ port ];

  # Monitor with Gatus like other services
  services.gatus.settings.endpoints = [
    {
      name = "outline";
      url = "https://outline.${domain}";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "outline health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];

  # Reverse proxy via Caddy
  services.caddy.virtualHosts = {
    "outline.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };
}
