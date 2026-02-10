# ntfy.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  name = "ntfy";
  port = 8081;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in {
  services.ntfy-sh.enable = true;
  services.ntfy-sh.settings = {
    base-url = "http://${ip}";
    listen-http = ":${toString port}";
  };

  networking.firewall.allowedTCPPorts = [port];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "http://${ip}:${toString port}";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
    }
  ];

  services.caddy.virtualHosts = {
    "${name}.${domain}" = {
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
