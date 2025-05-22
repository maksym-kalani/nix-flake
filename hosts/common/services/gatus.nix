{ config, pkgs, ... }:
{
  services.gatus = {
    enable = true;
    # you can override the package if you like
    package = pkgs.gatus;

    # instead of a single big configFile, you can
    # build it declaratively in Nix – and split it
    # across multiple modules/files via `imports`.
    settings = {
      web.port = 8080;

      # endpoints can be defined here (or in other
      # imported modules – they'll all get merged)
      endpoints = [
        {
          name      = "Morgana";
          url       = "http://192.168.2.20";
          interval  = "1m";
          conditions = [
            "[STATUS] == 200"
          ];
        }
      ];

      # configure a webhook notifier to ntfy.sh
      notifications.ntfy = {
        url = "http://192.168.2.50:8081";
        topic = "health";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
