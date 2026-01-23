{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.wallos;
  name = "wallos";
  port = 8282;
in {
  options.server.services.wallos = {
    enable = lib.mkEnableOption "Wallos subscription tracker";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "bellamy/wallos:latest";
        ports = [ "${toString port}:80" ];
        volumes = [
          "${config.server.containerData}/${name}/db:/var/www/html/db"
          "${config.server.containerData}/${name}/logos:/var/www/html/images/uploads/logos"
        ];
        environment = {
          TZ = "Europe/Kyiv";
        };
        autoStart = true;
      };
    }
  ]);
}
