# ntfy.nix
{ config, pkgs, lib, ... }:

{
  services.ntfy-sh.enable = true;
  services.ntfy-sh.settings = {
    base-url = "http://192.168.2.50";
    listen-http = ":8081";
  };
  
  networking.firewall.allowedTCPPorts = [ 8081 ];
  
  services.gatus.settings.endpoints = [
    {
      name      = "ntfy";
      url       = "http://192.168.2.50:8081";
      interval  = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
    }
  ];
  
  services.caddy.virtualHosts = 
  {
    "ntfy.laufin.xyz" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8081 {
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
