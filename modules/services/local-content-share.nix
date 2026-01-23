{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.local-content-share;
  name = "local-content-share";
  port = 8087;
in {
  options.server.services.local-content-share = {
    enable = lib.mkEnableOption "Local content share";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; subdomain = "share"; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "tanq16/local-content-share:main";
        ports = [ "${toString port}:8080" ];
        volumes = [
          "${config.server.containerData}/${name}:/app/data"
        ];
        autoStart = true;
      };
    }
  ]);
}
