{
  pkgs,
  lib,
  ...
}:
let
  ntfyLink = "http://192.168.2.50:8081";
  ntfyTopic = "health";
  port = 8080;
  morganaURL = "tcp://192.168.2.20:8006";
  morganaDependent = endpoint: {
    name = "${endpoint.name} availability";
    interval = "1m";
    timeout = "30s";
    endpoints = [
      {
        name = "Morgana for ${endpoint.name}";
        url = morganaURL;
        conditions = [ "[CONNECTED] == true" ];
        client.timeout = "5s";
        alerts = [ ];
      }
      endpoint
    ];
  };
in
{
  services.gatus = {
    enable = true;
    package = pkgs.gatus;

    settings = {
      web.port = 8080;

      alerting = {
        ntfy = {
          url = ntfyLink;
          topic = ntfyTopic;
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
          url = morganaURL;
          interval = "1m";
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
              success-threshold = 1;
            }
          ];
        }
        {
          name = "Home Assistant";
          url = "http://192.168.2.5:8123";
          interval = "1m";
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
              success-threshold = 1;
            }
          ];
        }
      ];

      # Separate suites keep a sibling failure from skipping another service.
      suites = map morganaDependent [
        {
          name = "Hermes";
          url = "http://192.168.2.205:9119/api/status";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "Hermes health check";
              failure-threshold = 3;
              success-threshold = 1;
            }
          ];
        }
        {
          name = "Cloudflare Tunnel";
          url = "https://matrix.laufin.online/";
          interval = "1m";
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
              success-threshold = 1;
            }
          ];
        }
        {
          name = "Kavita on Morgana";
          url = "http://192.168.2.201:5066";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "Kavita on Morgana health check";
              failure-threshold = 3;
              success-threshold = 1;
            }
          ];
        }
        {
          name = "Synapse on Morgana";
          url = "http://192.168.2.201:8008";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "Synapse on Morgana health check";
              failure-threshold = 3;
              success-threshold = 1;
            }
          ];
        }
        {
          name = "DNS 2 on Morgana";
          url = "http://192.168.2.207:5380";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "DNS 2 on Morgana health check";
              failure-threshold = 3;
              success-threshold = 1;
            }
          ];
        }
      ];
    };
  };

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Gatus";
      url = "gatus.laufin.xyz";
      icon = "arrow-up-box";
      enableGatus = false;
    })
  ];

  networking.firewall.allowedTCPPorts = [ port ];
}
