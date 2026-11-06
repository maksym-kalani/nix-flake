{
  lib,
  ...
}:
let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "wallos";

    image = "docker.io/bellamy/wallos@sha256:78b73a32ae24bcca67d6f4b96ca76fe29ee8da5e8df1769df1e612a4e776c904";

    port = {
      internal = 80;
      external = 8282;
    };

    extraOptions = [ ];
    volumes = [
      "${appdata}${cfg.name}/db:/var/www/html/db"
      "${appdata}${cfg.name}/logos:/var/www/html/images/uploads/logos"

    ];
    environmentVariables = {
      TZ = "Europe/Kyiv";

    };

    autoStart = true;
  };
in
{
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Wallos";
      url = "wallos.laufin.xyz";
      icon = "playlist-check";
      port = cfg.port.external;
      gatusName = cfg.name;
    })
  ];

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = [ "${toString cfg.port.external}:${toString cfg.port.internal}" ];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };

  networking.firewall.allowedTCPPorts = [ cfg.port.external ];

  systemd.tmpfiles.rules = [
    "d ${appdata}${cfg.name}/db :0755 :root :root -"
    "d ${appdata}${cfg.name}/logos :0755 :root :root -"
  ];
}
