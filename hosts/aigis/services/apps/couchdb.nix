{ config, pkgs, lib, ... }:
let
  name = "couchdb";
  port = 5984;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  appdata = "/mnt/tank/appdata/";
in
{
  services.couchdb = {
    enable = true;
    databaseDir = "${appdata}${name}/db";
    viewIndexDir = "${appdata}${name}/index";
    port = port;
    configFile = "${appdata}${name}/local.ini";
  };
  users.users.couchdb.extraGroups = [ "tankusers" ];
  networking.firewall.allowedTCPPorts = [ port ];
  
  systemd.tmpfiles.rules = [
    # Base directory for couchdb data/config
    "d ${appdata}${name} 0770 couchdb tankusers -"
    "d ${appdata}${name}/db 0770 couchdb tankusers -"
    "d ${appdata}${name}/index 0770 couchdb tankusers -"
    # Config file that ExecStartPre touches
    "f ${appdata}${name}/local.ini 0660 couchdb tankusers -"
  ];

  
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
}
