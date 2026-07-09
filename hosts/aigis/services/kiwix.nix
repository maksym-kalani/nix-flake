{
  ...
}:
let
  ip = "192.168.2.50";
  appdata = "/srv/kiwix";
  port = 8012;
  name = "kiwix";
in
{
  services.kiwix-serve = {
    enable = true;
    port = port;
    library = {
      "wikipedia_en_all_maxi_2025-08" = "${appdata}/wikipedia_en_all_maxi_2025-08.zim";
      "wikipedia_uk_all_maxi_2025-09" = "${appdata}/wikipedia_uk_all_maxi_2025-09.zim";
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
          description = "kiwix health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
