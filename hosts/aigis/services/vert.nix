{
  lib,
  ...
}:
let
  cfg = {
    name = "vert";

    image = "ghcr.io/vert-sh/vert@sha256:df3a22efeccf0e37adc3b4d01ecc1bd4ad2bc00ec44dc4672f74b23ba8f3ede9";

    port = {
      internal = 80;
      external = 7090;
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
      name = "Vert";
      url = "vert.laufin.xyz/";
      icon = "swap-vertical";
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
