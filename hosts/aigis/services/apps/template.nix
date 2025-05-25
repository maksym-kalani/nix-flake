# ntfy.nix
{ config, pkgs, lib, ... }:
let
  appName = "name";
  port = 0000;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in
{
  #services.ntfy-sh.enable = true;
  
  
  networking.firewall.allowedTCPPorts = [ port ];
  
  services.gatus.settings.endpoints = [
    {
      name      = appName;
      url       = "http://${ip}:${toString port}";
      interval  = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "Morgana health check";
          failure-threshold = 3;
          success-threshold = 2;
        }
      ];
    }
  ];
  
  services.caddy.virtualHosts = 
  {
    "${appName}.laufin.xyz" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port} {
          header_up Host {http.reverse_proxy.upstream.hostport}
        }
        @httpget {
          protocol http
          method GET
          path_regexp ^/([-_a-z0-9]{0,64}$|docs/|static/)
        }
        redir @httpget https://{host}{uri}
      '';
    };
  };
  
}
