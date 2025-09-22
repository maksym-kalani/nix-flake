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
    package = pkgs.transmission_4;
    settings = {
      download-dir = "/mnt/tank/media/downloads";
      openPeerPorts = true;
      performanceNetParameters = true;
      rpc-authentication-required = false;
      rpc-whitelist = "127.0.0.1,${ip}";
      rpc-host-whitelist = "${name}.${domain}";
      rpc-bind-address = "0.0.0.0";
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
