{
  lib,
  ...
}:
let
  cfg = {
    name = "omni-tools";

    image = "docker.io/iib0011/omni-tools@sha256:99e21d937dbe5ff86f00ac06ce17b5507a81911fa8d781f9b244b4067350e1a7";

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
