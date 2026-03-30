{
  ...
}:
let
  name = "immich";
  port = 2283;
  ip = "192.168.2.50";
in
{
  services.immich.enable = true;
  services.immich.host = ip;
  services.immich.port = port;

  services.immich.mediaLocation = "/mnt/tank/media/photos/immich";

  services.immich.group = "tankusers";

  services.immich.openFirewall = true;

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
