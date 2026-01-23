{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.omni-tools;
  name = "omni-tools";
  port = 8086;
in {
  options.server.services.omni-tools = {
    enable = lib.mkEnableOption "Omni Tools collection";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "iib0011/omni-tools:latest";
        ports = [ "${toString port}:80" ];
        autoStart = true;
      };
    }
  ]);
}
