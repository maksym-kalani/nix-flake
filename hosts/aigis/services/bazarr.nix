{
  ...
}:
let
  name = "bazarr";
  port = 6767;
  ip = "192.168.2.50";
in
{
  services.bazarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.bazarr.extraGroups = [ "tankusers" ];

  networking.firewall.allowedTCPPorts = [ port ];

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
