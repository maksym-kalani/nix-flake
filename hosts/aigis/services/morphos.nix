{
  lib,
  ...
}:
let
  cfg = {
    name = "morphos";

    image = "ghcr.io/danvergara/morphos-server:latest";

    port = {
      internal = 8080;
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
      name = "Morphos";
      url = "morphos.laufin.xyz/";
      icon = "reload";
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
