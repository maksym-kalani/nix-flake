{ config, pkgs, lib, ... }:
let
  name = "transmission";
  port = 9091;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.transmission = {
      enable = true;
      settings = {
        download-dir = "/mnt/tank/downloads";
        incomplete-dir = "/mnt/tank/downloads/.incomplete/";
        incomplete-dir-enabled = true;
      };
    };
  users.users.transmission.extraGroups = [ "tankusers" ];
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
