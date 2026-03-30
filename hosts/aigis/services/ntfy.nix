{
  ...
}: let
  name = "ntfy";
  port = 8081;
  ip = "192.168.2.50";
in {
  services.ntfy-sh.enable = true;
  services.ntfy-sh.settings = {
    base-url = "http://${ip}";
    listen-http = ":${toString port}";
  };

  networking.firewall.allowedTCPPorts = [port];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "http://${ip}:${toString port}";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
    }
  ];
}
