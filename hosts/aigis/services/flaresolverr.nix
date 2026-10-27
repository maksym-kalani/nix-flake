{
  ...
}:
let
  name = "flaresolverr";
  port = 8191;
  ip = "192.168.2.50";
in
{
  services.flaresolverr = {
    enable = true;
    inherit port;
  };

  networking.firewall.allowedTCPPorts = [ port ];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "http://${ip}:${toString port}/health";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
        "[BODY].status == ok"
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
