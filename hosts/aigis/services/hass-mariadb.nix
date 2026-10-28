{
  config,
  ...
}:
let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "hass-mariadb";
    image = "docker.io/library/mariadb@sha256:f4054da26e3a9dd6c8b5cc97363e544408b15c0fb369d7359c25dc04826eb6e1";
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
