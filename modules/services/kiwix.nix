{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.kiwix;
  name = "kiwix";
  port = 8012;
in {
  options.server.services.kiwix = {
    enable = lib.mkEnableOption "Kiwix offline content server";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "ghcr.io/kiwix/kiwix-serve:latest";
        ports = [ "${toString port}:8080" ];
        volumes = [
          "/srv/kiwix:/data:ro"
        ];
        extraOptions = [ "--userns=host" ];
        cmd = [ "*.zim" ];
        autoStart = true;
      };
    }
  ]);
}
