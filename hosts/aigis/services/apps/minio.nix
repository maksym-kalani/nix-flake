{ config, pkgs, lib, ... }:
let
  name = "minio";
  port = 9096;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.minio = {
      enable = true;
      browser = true; # Enable or disable access to web UI.
  
      dataDir = [ "/mnt/tank/appdata/minio/data" ];
      configDir = "/mnt/tank/appdata/minio/config";
      listenAddress = "${ip}:9096";
      consoleAddress = "${ip}:9097"; # Web UI
      region = "us-east-1"; # default to us-east-1, same as AWS S3.
  
      # File containing the MINIO_ROOT_USER, default is “minioadmin”, and MINIO_ROOT_PASSWORD (length >= 8), default is “minioadmin”;
      rootCredentialsFile = config.sops.secrets.minio.path;
    };
  users.users.minio.extraGroups = [ "tankusers" ];
  networking.firewall.allowedTCPPorts = [ port 9097 ];
  
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
