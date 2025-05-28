{ config, pkgs, lib, ... }:
let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  name = "gatus";
  ntfyLink = "http://192.168.2.50:8081";
  ntfyTopic = "health";
  port = 8080;
in
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

      # configure a webhook notifier to ntfy.sh
      alerting = {
        ntfy = {
          url = ntfyLink;
          topic = ntfyTopic;
          priority = 3;
          default-alert = {
            enable = true;
            failure-threshold = 3;
            success-threshold = 2;
            send-on-resolved = true;
          };
        };
      };
    };
  };
  
  services.caddy.virtualHosts = 
  {
    "${name}.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };
    
  networking.firewall.allowedTCPPorts = [ port ];
}
