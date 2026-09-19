{
  lib,
  ...
}: let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "wallos";

    image = "bellamy/wallos:latest";

    port = {
      internal = 80;
      external = 8282;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}/db:/var/www/html/db"
      "${appdata}${cfg.name}/logos:/var/www/html/images/uploads/logos"

    ];
    environmentVariables = {
      TZ = "Europe/Kyiv";

    };

    autoStart = true;
  };
in {
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
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };

  networking.firewall.allowedTCPPorts = [cfg.port.external];
}
