{
  lib,
  ...
}:
let
  cfg = {
    name = "omni-tools";

    image = "docker.io/iib0011/omni-tools@sha256:9a94e6ebc8dada2c7a5607b232214307e6f903a7747878602281ecdb79ced851"; # pinned to what aigis ran on 2026-10-27

    port = {
      internal = 80;
      external = 8086;
    };

    extraOptions = [ ];
    volumes = [ ];
    environmentVariables = { };

    autoStart = true;
  };
in
{
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Omni-Tools";
      url = "omni-tools.laufin.xyz";
      icon = "hammer-screwdriver";
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
}
