{ config, pkgs, lib, ... }:
let
  name = "deluge";
  port = 8112;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.deluge = {
      enable = true;
      declarative = true;
      dataDir = "/mnt/tank/appdata/deluge";
      openFirewall = true;
      authFile = config.sops.secrets.deluge_auth.path;
      config = {
        download_location = "/mnt/tank/downloads";
        max_upload_speed = "1000.0";
        share_ratio_limit = "2.0";
        allow_remote = true;
      };
      extraPackages = [
        pkgs.unzip
        pkgs.gnutar
        pkgs.xz
        pkgs.bzip2
      ];
      web = {
        enable = true;
        openFirewall = true;
        port = port;
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
