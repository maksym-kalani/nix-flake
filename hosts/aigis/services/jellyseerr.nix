{
  ...
}:
let
  name = "jellyseerr";
  port = 5055;
  ip = "192.168.2.50";
in
{
  services.seerr = {
    enable = true;
    openFirewall = true;
  };

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
