{
  lib,
  ...
}:
let
  cfg = {
    name = "vert";

    image = "ghcr.io/vert-sh/vert@sha256:51edb89e7c57197b0281ba8427fb27eea63730a3683b10d422061afab2708a49"; # pinned to what aigis ran on 2026-10-27

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