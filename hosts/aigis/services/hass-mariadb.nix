{
  config,
  ...
}:
let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "hass-mariadb";
    # MariaDB LTS; the watchdog follows the official lts lookup channel.
    image = "docker.io/library/mariadb@sha256:4aaf88b3106382c8c18e49f0cec60267be618fc22f858c4503afb2a2555afed3";
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
