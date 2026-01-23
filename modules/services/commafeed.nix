{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.commafeed;
  name = "commafeed";
  port = 8552;
in {
  options.server.services.commafeed = {
    enable = lib.mkEnableOption "Commafeed RSS reader";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "athou/commafeed:latest-h2";
        ports = [ "${toString port}:8082" ];
        autoStart = true;
      };
    }
  ]);
}
