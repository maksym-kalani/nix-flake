{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.ntfy;
  name = "ntfy";
  port = 8081;
in {
  options.server.services.ntfy = {
    enable = lib.mkEnableOption "ntfy notification service";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      networking.firewall.allowedTCPPorts = [ port ];

      services.gatus.settings.endpoints = [{
        name = name;
        url = "http://${config.server.ip}:${toString port}";
        interval = "1m";
        conditions = [ "[STATUS] == 200" ];
      }];

      services.caddy.virtualHosts."${name}.${config.server.domain}".extraConfig = ''
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

      services.ntfy-sh.enable = true;
      services.ntfy-sh.settings = {
        base-url = "http://${config.server.ip}";
        listen-http = ":${toString port}";
      };
    }
  ]);
}
