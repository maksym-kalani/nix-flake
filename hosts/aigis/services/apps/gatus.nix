{ config, pkgs, lib, ... }:
let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  name = "gatus";
  ntfyLink = "http://192.168.2.50:8081";
  ntfyTopic = "health";
  port = 8080;
in
{
  services.gatus = {
    enable = true;
    # you can override the package if you like
    package = pkgs.gatus;

    # instead of a single big configFile, you can
    # build it declaratively in Nix – and split it
    # across multiple modules/files via `imports`.
    settings = {
      web.port = 8080;

      # configure a webhook notifier to ntfy.sh
      alerting = {
        ntfy = {
          url = ntfyLink;
          topic = ntfyTopic;
          priority = 3;
          default-alert = {
            enable = true;
            failure-threshold = 3;
            success-threshold = 2;
            send-on-resolved = true;
          };
        };
      };
      
      endpoints = [
        {
          name      = "Morgana";
          url       = "tcp://192.168.2.20:8006";
          interval  = "1m";
          conditions = [
            "[CONNECTED] == true"
          ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "Morgana health check";
              failure-threshold = 3;
              success-threshold = 2;
            }
          ];
        }
        {
          name      = "Home Assistant";
          url       = "http://192.168.2.5:8123";
          interval  = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "Home Assistant health check";
              failure-threshold = 3;
              success-threshold = 2;
            }
          ];
        }
        {
          name      = "Cloudflare Tunnel";
          url       = "https://matrix.laufin.online/";
          interval  = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "Cloudflare Tunnel health check";
              failure-threshold = 3;
              success-threshold = 2;
            }
          ];
        }
      ];
    };
  };
  
  services.caddy.virtualHosts = 
  {
    "${name}.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };
    
  networking.firewall.allowedTCPPorts = [ port ];
}
