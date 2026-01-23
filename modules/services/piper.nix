{ config, lib, ... }:
let
  cfg = config.server.services.piper;
  name = "piper";
  port = 10200;
in {
  options.server.services.piper = {
    enable = lib.mkEnableOption "Piper TTS service";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ port ];

    services.gatus.settings.endpoints = [{
      name = name;
      url = "tcp://${config.server.ip}:${toString port}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" ];
      alerts = [{
        type = "ntfy";
        enabled = true;
        send-on-resolved = true;
        description = "${name} health check";
        failure-threshold = 3;
        success-threshold = 1;
      }];
    }];

    virtualisation.oci-containers.containers.${name} = {
      image = "rhasspy/wyoming-piper:latest";
      ports = [ "${toString port}:10200" ];
      volumes = [
        "${config.server.containerData}/${name}:/config"
      ];
      environment = {
        voice = "en_US-amy-medium";
      };
      cmd = [ "--voice=en_US-lessac-medium" ];
      autoStart = true;
    };
  };
}
