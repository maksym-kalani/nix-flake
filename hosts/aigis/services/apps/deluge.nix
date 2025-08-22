{ config, pkgs, lib, ... }:
let
  name = "deluge";
  port = 9150;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.deluge = {
      enable = true;
      dataDir = "/mnt/tank/downloads";
      openFirewall = true;
      extraPackages = [
        pkgs.unzip
        pkgs.gnutar
        pkgs.xz
        pkgs.bzip2
      ];
      web = {
        enable = true;
        openFirewall = true;
      };
    };
  users.users.deluge.extraGroups = [ "tankusers" ];
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
