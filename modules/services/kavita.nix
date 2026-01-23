{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.kavita;
  name = "kavita";
  port = 5000;
in {
  options.server.services.kavita = {
    enable = lib.mkEnableOption "Kavita manga/book server";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "jvmilazz0/kavita:latest";
        ports = [ "${toString port}:5000" ];
        volumes = [
          "/mnt/tank/media/ttrpgs:/ttrpgs"
          "${config.server.containerData}/${name}:/kavita/config"
        ];
        autoStart = true;
      };
    }
  ]);
}
