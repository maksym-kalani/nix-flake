{ config, pkgs, lib, ... }:
let
  name = "immich";
  port = 2283;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.immich.enable = true;
  # Listen on all network interfaces (for reverse proxy access) over HTTP
  services.immich.host = ip;
  services.immich.port = port;

  # Store media on the ZFS pool mount (existing directory on /mnt/tank)
  services.immich.mediaLocation = "/mnt/tank/appdata/immich";

  # Run Immich under the 'tankusers' group for write access to media directory
  services.immich.group = "tankusers";

  # Open the firewall for Immich's port (allow access from 192.168.2.205)
  services.immich.openFirewall = true;
  
  services.gatus.settings.endpoints = [
    {
      name      = name;
      url       = "http://${ip}:${toString port}";
      interval  = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
  
  services.caddy.virtualHosts = 
  {
    "${name}.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };
  
}
