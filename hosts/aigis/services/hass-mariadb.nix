{
  config,
  ...
}:
let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "hass-mariadb";
    # MariaDB 12.3.3 LTS; frozen in the watchdog's Renovate exclusions.
    image = "docker.io/library/mariadb@sha256:d46e102fa8b9b72bfcdeb56f9dd538742092119dc8b11f31fe662605cd234cd9";
    port = {
      internal = 3306;
      external = 3306;
    };
    extraOptions = [ ];
    volumes = [
      "${appdata}${cfg.name}:/var/lib/mysql"
    ];
    environmentVariables = {
      MYSQL_DATABASE = "hass";
      MYSQL_USER = "hass";
    };
    autoStart = true;
  };
in
{
  sops.secrets = {
    hass_mariadb_root_password = { };
    hass_mariadb_password = { };
  };

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = [ "${toString cfg.port.external}:${toString cfg.port.internal}" ];

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

  systemd.tmpfiles.rules = [ "d ${appdata}${cfg.name} :0755 :root :root -" ];
}
