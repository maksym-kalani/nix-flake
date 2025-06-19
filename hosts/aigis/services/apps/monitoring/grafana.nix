{ config, pkgs, lib, ... }:
let
  name = "grafana";
  port = 3003;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  lokiUrl = "http://127.0.0.1:3100";
in
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "192.168.2.50";
        http_port = port;
        # optionally enforce_domain, enable_gzip, set own domain…
      };
    };
    # automatically add Loki as a data source:
    provision.datasources = {
        # You must choose EITHER `settings` OR `path`, not both
        settings = {
          apiVersion = 1;  # required by Grafana’s provisioning spec
          datasources = [
          {
            name      = "Loki";
            type      = "loki";
            access    = "proxy";
            url       = lokiUrl;
            isDefault = true;
            orgId     = 1;
            uid       = "loki-default";
          }
        ];
      };
    };
  };
  
  systemd.services."grafana-server" = {
    after = [ "network-interfaces.target" ];
    wants = [ "network-interfaces.target" ];
    after = [ "loki.target" ];
    wants = [ "loki.target" ];
  };
  
  networking.firewall.allowedTCPPorts = [ port ];
    
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
          success-threshold = 2;
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