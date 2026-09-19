{
  lib,
  ...
}: let
  cfg = {
    name = "it-tools";

    image = "corentinth/it-tools:latest";

    port = {
      internal = 80;
      external = 8384;
    };

    extraOptions = [];
    volumes = [];
    environmentVariables = {};

    autoStart = true;
  };
in {
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "IT Tools";
      url = "it-tools.laufin.xyz";
      icon = "tools";
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
