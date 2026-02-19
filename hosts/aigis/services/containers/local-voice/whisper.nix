{ ... }:
let
  appdata = "/var/lib/containers/";
  ip = "192.168.2.50";
  cfg = {
    name = "whisper";
    image = "rhasspy/wyoming-whisper";
    port = {
      internal = 10300; # Port inside the container
      external = 10300; # Port on the host
    };
    extraOptions = [
      #"--tty"
      #"--stdin_open"
    ];
    volumes = [
      "${appdata}${cfg.name}:/data"
    ];
    environmentVariables = { };
    autoStart = true;
    cmd = [
      "--model=tiny-int8"
      "--language=en"
    ];
  };
in
{
  # Container definition
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = [ "${toString cfg.port.external}:${toString cfg.port.internal}" ];

    # Optional configs
    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
    cmd = cfg.cmd;
  };

  networking.firewall.allowedTCPPorts = [ cfg.port.external ];

  services.gatus.settings.endpoints = [
    {
      name = cfg.name;
      url = "tcp://${ip}:${toString cfg.port.external}";
      interval = "1m";
      conditions = [
        "[CONNECTED] == true"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${cfg.name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
