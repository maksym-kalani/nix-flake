{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.mazanoke;
  name = "mazanoke";
  port = 3474;
in {
  options.server.services.mazanoke = {
    enable = lib.mkEnableOption "Mazanoke image optimizer";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "ghcr.io/civilblur/mazanoke:latest";
        ports = [ "${toString port}:80" ];
        autoStart = true;
      };
    }
  ]);
}
