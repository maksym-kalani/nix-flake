{ config, pkgs, lib, ... }:
let
  name = "sonarr";
  port = 8989;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.sonarr = { enable = true; openFirewall = true; };
  users.users.sonarr.extraGroups = [ "tankusers" ];
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
