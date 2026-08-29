{
  pkgs
  ...
}:
let
  ip = "192.168.2.50";
  port = 7080;
  name = "stirling-pdf";
in
{
  services.stirling-pdf = {
    package = pkgs.stable.stirling-pdf;
    enable = true;
    environment = {
      SERVER_PORT = port;
      SECURITY_ENABLELOGIN = false;
      SYSTEM_DEFAULTLOCALE = "en-US";
      SYSTEM_GOOGLEVISIBILITY = true;
      SYSTEM_MAXFILESIZE = "1000";
      UI_APPNAMENAVBAR = "Stirling-PDF-Ultra-lite Latest";
    };
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
