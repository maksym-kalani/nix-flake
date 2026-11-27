{
  lib,
  ...
}:
let
  cfg = {
    name = "vert";

    image = "ghcr.io/vert-sh/vert@sha256:67cc0ecfcc81ea6c0c7dd730582acc1093cd2e97a96f365fa5b69d7bc0edbd8b";

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
