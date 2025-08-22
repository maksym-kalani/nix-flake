{ config, pkgs, lib, ... }:
let
  name = "prowlarr";
  port = 9696;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    dataDir = "/mnt/tank/appdata/prowlarr";
  };

  users.groups.prowlarr = {};
  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [ "tankusers" ];
  };
  
  systemd.tmpfiles.rules = [
    "d /mnt/tank/appdata/prowlarr 0750 prowlarr tankusers -"
  ];

  systemd.services.prowlarr.serviceConfig = {
    ExecStart = lib.mkForce "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=/mnt/tank/appdata/prowlarr";
    DynamicUser = lib.mkForce false;
    User = "prowlarr";
    Group = "prowlarr";
    ReadWritePaths = [ "/mnt/tank/appdata/prowlarr" ];
    UMask = "007"; # optional
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
