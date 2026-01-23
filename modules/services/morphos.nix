{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.morphos;
  name = "morphos";
  port = 7090;
in {
  options.server.services.morphos = {
    enable = lib.mkEnableOption "Morphos file converter";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "ghcr.io/danvergara/morphos-server:latest";
        ports = [ "${toString port}:8080" ];
        autoStart = true;
      };
    }
  ]);
}
