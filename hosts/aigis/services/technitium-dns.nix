{
  ...
}:
let
  ip = "192.168.2.50";
  port = 5380;
  name = "dns";
in
{
  services.technitium-dns-server.enable = true;

  networking.firewall.allowedTCPPorts = [ port 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "http://${ip}:${toString port}";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
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
