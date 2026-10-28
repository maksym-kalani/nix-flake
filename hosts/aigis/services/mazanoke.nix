{
  lib,
  ...
}:
let
  cfg = {
    name = "mazanoke";

    image = "ghcr.io/civilblur/mazanoke@sha256:ca83cddd90cd1e4b43102884bf39025731a1c7569f3bbda9d6530de72528cbab";

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
