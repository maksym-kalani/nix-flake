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
    group = "tankusers";
    configFile = "${appdata}${name}/local.ini";
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
}
