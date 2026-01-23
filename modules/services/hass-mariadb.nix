{ config, lib, ... }:
let
  cfg = config.server.services.hass-mariadb;
  name = "hass-mariadb";
  port = 3306;
in {
  options.server.services.hass-mariadb = {
    enable = lib.mkEnableOption "MariaDB for Home Assistant";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ port ];

    virtualisation.oci-containers.containers.${name} = {
      image = "mariadb";
      ports = [ "${toString port}:3306" ];
      volumes = [
        "${config.server.containerData}/${name}:/var/lib/mysql"
      ];
      environment = {
        MYSQL_DATABASE = "hass";
        MYSQL_USER = "hass";
      };
      environmentFiles = [
        config.sops.secrets.hass_mariadb_password.path
        config.sops.secrets.hass_mariadb_root_password.path
      ];
      autoStart = true;
    };
  };
}
