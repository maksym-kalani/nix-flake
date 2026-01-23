{ config, pkgs, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.gatus;
  name = "gatus";
  port = 8080;
in {
  options.server.services.gatus = {
    enable = lib.mkEnableOption "Gatus monitoring service";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      networking.firewall.allowedTCPPorts = [ port ];

      services.caddy.virtualHosts."${name}.${config.server.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';

      services.gatus = {
        enable = true;
        package = pkgs.gatus;
        settings = {
          web.port = port;
          alerting = {
            ntfy = {
              url = "http://${config.server.ip}:8081";
              topic = "health";
              priority = 3;
              default-alert = {
                enable = true;
                failure-threshold = 3;
                success-threshold = 1;
                send-on-resolved = true;
              };
            };
          };
          endpoints = [
            {
              name = "Morgana";
              url = "tcp://192.168.2.20:8006";
              interval = "1m";
              conditions = [ "[CONNECTED] == true" ];
              alerts = [{
                type = "ntfy";
                enabled = true;
                send-on-resolved = true;
                description = "Morgana health check";
                failure-threshold = 3;
                success-threshold = 1;
              }];
            }
            {
              name = "Home Assistant";
              url = "http://192.168.2.5:8123";
              interval = "1m";
              conditions = [ "[STATUS] == 200" ];
              alerts = [{
                type = "ntfy";
                enabled = true;
                send-on-resolved = true;
                description = "Home Assistant health check";
                failure-threshold = 3;
                success-threshold = 1;
              }];
            }
            {
              name = "Cloudflare Tunnel";
              url = "https://matrix.laufin.online/";
              interval = "1m";
              conditions = [ "[STATUS] == 200" ];
              alerts = [{
                type = "ntfy";
                enabled = true;
                send-on-resolved = true;
                description = "Cloudflare Tunnel health check";
                failure-threshold = 3;
                success-threshold = 1;
              }];
            }
            {
              name = "Kavita on Morgana";
              url = "http://192.168.2.201:5066";
              interval = "1m";
              conditions = [ "[STATUS] == 200" ];
              alerts = [{
                type = "ntfy";
                enabled = true;
                send-on-resolved = true;
                description = "Kavita on Morgana health check";
                failure-threshold = 3;
                success-threshold = 1;
              }];
            }
            {
              name = "Synapse on Morgana";
              url = "http://192.168.2.201:8008";
              interval = "1m";
              conditions = [ "[STATUS] == 200" ];
              alerts = [{
                type = "ntfy";
                enabled = true;
                send-on-resolved = true;
                description = "Synapse on Morgana health check";
                failure-threshold = 3;
                success-threshold = 1;
              }];
            }
            {
              name = "DNS 2 on Morgana";
              url = "http://192.168.2.207:5380";
              interval = "1m";
              conditions = [ "[STATUS] == 200" ];
              alerts = [{
                type = "ntfy";
                enabled = true;
                send-on-resolved = true;
                description = "DNS 2 on Morgana health check";
                failure-threshold = 3;
                success-threshold = 1;
              }];
            }
          ];
        };
      };
    }
  ]);
}
