{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.searxng;
  name = "search";
  port = 8882;
in {
  options.server.services.searxng = {
    enable = lib.mkEnableOption "SearXNG metasearch engine";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "searxng/searxng:latest";
        ports = [ "${toString port}:8080" ];
        volumes = [
          "${config.server.containerData}/${name}:/etc/searxng"
        ];
        autoStart = true;
      };
    }
  ]);
}
