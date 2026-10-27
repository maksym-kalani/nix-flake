{
  lib,
  ...
}: let
  cfg = {
    name = "matrix-admin";

    image = "docker.io/awesometechnologies/synapse-admin@sha256:a1c1f4662875f51ff1ca556a9eb7c802d9bc40ef58747b9efc163b42da3ad416";

    port = {
      internal = 80;
      external = 7373;
    };

    extraOptions = [];
    volumes = [];
    environmentVariables = {};

    autoStart = true;
  };
in {
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Matrix Admin";
      url = "matrix-admin.laufin.xyz";
      icon = "shield-crown";
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
