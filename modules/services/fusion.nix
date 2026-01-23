{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.fusion;
  name = "fusion";
  port = 8085;
in {
  options.server.services.fusion = {
    enable = lib.mkEnableOption "Fusion RSS reader";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "ghcr.io/0x2e/fusion:latest";
        ports = [ "${toString port}:8080" ];
        volumes = [
          "${config.server.containerData}/${name}:/data"
        ];
        environment = {
          PASSWORD = "";
        };
        autoStart = true;
      };
    }
  ]);
}
