{ config, lib, ... }:
let
  cfg = config.server.services.whisper;
  name = "whisper";
  port = 10300;
in {
  options.server.services.whisper = {
    enable = lib.mkEnableOption "Whisper STT service";
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
      image = "rhasspy/wyoming-whisper";
      ports = [ "${toString port}:10300" ];
      volumes = [
        "${config.server.containerData}/${name}:/data"
      ];
      cmd = [ "--model=tiny-int8" "--language=en" ];
      autoStart = true;
    };
  };
}
