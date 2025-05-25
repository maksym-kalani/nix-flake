{ config, pkgs, ... }:
let
  name = "loki";
  port = 3100;
  domain = "laufin.xyz";
in
{
    services.loki = {
      enable = true;
      configFile = ./loki-local-config.yaml;
    };

  
  # Open firewall port
  networking.firewall.allowedTCPPorts = [ port ];
  
  # Optional: Add Loki to your Gatus monitoring
  services.gatus.settings.endpoints = [
    {
      name = "loki";
      url = "http://192.168.2.50:${toString port}/ready";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "Loki health check";
          failure-threshold = 3;
          success-threshold = 2;
        }
      ];
    }
  ];
  
  # Optional: Caddy reverse proxy configuration
  services.caddy.virtualHosts = {
    "${name}.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };
}