{
  lib,
  ...
}:
let
  cfg = {
    name = "mazanoke";

    image = "ghcr.io/civilblur/mazanoke@sha256:92cc7474deb789af6549318563b7a9ee750131f9f7b297cc9c87ab67e656c22c";

    port = {
      internal = 80;
      external = 3474;
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
      name = "Mazanoke";
      url = "mazanoke.laufin.xyz/";
      icon = "image-auto-adjust";
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
