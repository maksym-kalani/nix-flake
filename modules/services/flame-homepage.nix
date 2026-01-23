{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.flame-homepage;
  name = "home";
  port = 3311;
in {
  options.server.services.flame-homepage = {
    enable = lib.mkEnableOption "Flame homepage dashboard";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "pawelmalak/flame:latest";
        ports = [ "${toString port}:5005" ];
        volumes = [
          "${config.server.containerData}/${name}:/app/data"
        ];
        environmentFiles = [ config.sops.secrets.flame_homepage_password.path ];
        autoStart = true;
      };
    }
  ]);
}
