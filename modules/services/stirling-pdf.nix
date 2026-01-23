{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.stirling-pdf;
  name = "stirling-pdf";
  port = 7080;
in {
  options.server.services.stirling-pdf = {
    enable = lib.mkEnableOption "Stirling PDF tools";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "frooodle/s-pdf:latest-ultra-lite";
        ports = [ "${toString port}:8080" ];
        volumes = [
          "${config.server.containerData}/${name}/config:/configs:rw"
          "${config.server.containerData}/${name}/logs:/logs:rw"
        ];
        environment = {
          DOCKER_ENABLE_SECURITY = "false";
          SECURITY_ENABLELOGIN = "false";
          SYSTEM_DEFAULTLOCALE = "en-US";
          UI_APPNAME = "Stirling-PDF-Ultra-lite";
          UI_HOMEDESCRIPTION = "Demo site for Stirling-PDF-Ultra-lite Latest";
          UI_APPNAMENAVBAR = "Stirling-PDF-Ultra-lite Latest";
          SYSTEM_MAXFILESIZE = "1000";
          METRICS_ENABLED = "false";
          SYSTEM_GOOGLEVISIBILITY = "true";
        };
        autoStart = true;
      };
    }
  ]);
}
