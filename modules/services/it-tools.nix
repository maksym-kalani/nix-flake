{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.it-tools;
  name = "it-tools";
  port = 8384;
in {
  options.server.services.it-tools = {
    enable = lib.mkEnableOption "IT Tools collection";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "corentinth/it-tools:latest";
        ports = [ "${toString port}:80" ];
        autoStart = true;
      };
    }
  ]);
}
