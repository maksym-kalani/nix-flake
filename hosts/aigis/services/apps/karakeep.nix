{ config, pkgs, lib, ... }:
let
  name = "karakeep";
  port = 3050;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.karakeep = {
      enable = true;
      extraEnvironment = {
        PORT = "${toString port}";
        NEXTAUTH_URL = "${name}.${domain}";
        DISABLE_NEW_RELEASE_CHECK = "true";
        OCR_LANGS = "eng,ukr";
      };
      environmentFile = config.sops.secrets.openai_api_key.path;
    };
  
  services.meilisearch = {
    enable = true;
    package = pkgs.meilisearch;
  };
  
  systemd.services.karakeep-backup = {
    description = "Backup Karakeep Data";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.rsync}/bin/rsync -a --delete /var/lib/karakeep/ /mnt/tank/appdata/karakeep/";
      User = "root";
      Group = "root";
    };
  };
  
  systemd.timers.karakeep-backup = {
    description = "Run Karakeep backup daily at 4 AM";
    wantedBy = [ "timers.target" ];
    requires = [ "karakeep-backup.service" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
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
