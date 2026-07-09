{ ... }:
let
  ip = "192.168.2.50";
  port = 10200;
  name = "piper";
in
{
  services.wyoming.piper.servers.${name} = {
    enable = true;
    uri = "tcp://0.0.0.0:${toString port}";
    voice = "en_US-lessac-medium";
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
