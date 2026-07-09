{ ... }:
let
  ip = "192.168.2.50";
  port = 10300;
  name = "whisper";
in
{
  services.wyoming.faster-whisper.servers.${name} = {
    enable = true;
    uri = "tcp://0.0.0.0:${toString port}";
    sttLibrary = "faster-whisper";
    model = "tiny-int8";
    language = "en";
    device = "cpu";
    zeroconf.enable = false;
  };

  networking.firewall.allowedTCPPorts = [ port ];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "tcp://${ip}:${toString port}";
      interval = "1m";
      conditions = [
        "[CONNECTED] == true"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
