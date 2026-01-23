{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.recommendarr;
  name = "recommendarr";
  port = 3007;
in {
  options.server.services.recommendarr = {
    enable = lib.mkEnableOption "Recommendarr media recommendations";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "tannermiddleton/recommendarr:latest";
        ports = [ "${toString port}:3000" ];
        volumes = [
          "${config.server.containerData}/${name}:/app/server/data"
        ];
        autoStart = true;
      };
    }
  ]);
}
