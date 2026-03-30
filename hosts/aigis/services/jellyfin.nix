{
  ...
}: let
  name = "jellyfin";
  port = 8096;
  ip = "192.168.2.50";
in {
  services.jellyfin.enable = true;
  users.users.jellyfin.extraGroups = ["tankusers" "render" "video"];

  networking.firewall.allowedTCPPorts = [port];

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
