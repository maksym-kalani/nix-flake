{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.matrix-admin;
  name = "matrix-admin";
  port = 7373;
in {
  options.server.services.matrix-admin = {
    enable = lib.mkEnableOption "Synapse Admin interface";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "awesometechnologies/synapse-admin";
        ports = [ "${toString port}:80" ];
        autoStart = true;
      };
    }
  ]);
}
