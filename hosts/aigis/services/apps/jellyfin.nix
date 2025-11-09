{ config, pkgs, lib, ... }:
let
  name = "jellyfin";
  port = 8096;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  mkBackupJob = import ../lib/mk-backup-job.nix { inherit pkgs; };
in
mkBackupJob {
  name = name;
  src = "/var/lib/jellyfin/";
  dest = "/mnt/tank/appdata/${name}/";
  schedule = "*-*-* 04:00:00";
}
{
  services.jellyfin.enable = true;
  #services.jellyfin.configDir = "/mnt/tank/appdata/jellyfin";
  users.users.jellyfin.extraGroups = [ "tankusers" "render" "video" ];
  
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
