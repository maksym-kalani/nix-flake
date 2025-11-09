{ lib, config, ... }:

let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  appdata = "/var/lib/containers/";
  cfg = {
    name = "hass-mariadb";
    image = "mariadb";
    port = {
      internal = 3306; # Port inside the container
      external = 3306; # Port on the host
    };
    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}:/var/lib/mysql"
    ];
    environmentVariables = {
      MYSQL_DATABASE = "hass";
      MYSQL_USER = "hass";
    };
    autoStart = true;
  };
in {
  # Container definition
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];
    
    # Optional configs
    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
    environmentFiles = [
      config.sops.secrets.hass_mariadb_password.path 
      config.sops.secrets.hass_mariadb_root_password.path
    ];
  };
  
  networking.firewall.allowedTCPPorts = [ cfg.port.external ];
}