{
  pkgs,
  ...
}:
let
  name = "vikunja";
  port = 1337;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  services.vikunja = {
    package = pkgs.vikunja;
    enable = true;
    port = port;
    frontendHostname = "todo.${domain}";
    frontendScheme = "https";
  };

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
