{ lib, config, ... }:

let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  appdata = "/mnt/tank/appdata/";
  cfg = {
    name = "couchdb";
    image = "couchdb:3.3.3";
    port = {
      internal = 5984; # Port inside the container
      external = 5984; # Port on the host
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}/data:/opt/couchdb/data"
      "${appdata}${cfg.name}/local.d:/opt/couchdb/etc/local.d"
    ];
    environmentVariables = {
      COUCHDB_USER = "obsidian_user";
    };
    autoStart = true;
  };
in {
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];
    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
    environmentFiles = [config.sops.secrets.couchdb_password.path];
  };
  
  networking.firewall.allowedTCPPorts = [ cfg.port.external ];
  
  services.gatus.settings.endpoints = [
    {
      name      = cfg.name;
      url       = "http://${ip}:${toString cfg.port.external}";
      interval  = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${cfg.name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}