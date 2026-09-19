{
  lib,
  ...
}: let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "recommendarr";

    image = "tannermiddleton/recommendarr:latest";

    port = {
      internal = 3000;
      external = 3007;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}:/app/server/data"

    ];
    environmentVariables = {};

    autoStart = true;
  };
in {
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Recommendarr";
      url = "recommendarr.laufin.xyz";
      icon = "television-classic";
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
