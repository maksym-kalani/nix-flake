{
  pkgs,
  config,
  ...
}:
let
  caddyfile = config.sops.templates."Caddyfile".path;
in
{
  sops.templates."Caddyfile" = {
    owner = "caddy";
    content = ''
      *.laufin.xyz {
        tls {
          dns namecheap {
            api_key ${config.sops.placeholder.namecheap_api_key}
            user ${config.sops.placeholder.namecheap_api_user}
            api_endpoint https://api.namecheap.com/xml.response
          }
        }

        @portainer host portainer.laufin.xyz
        handle @portainer {
          encode gzip
          reverse_proxy https://192.168.2.201:9443 {
            header_up Host {host}
            header_up X-Real-IP {client_host}
            header_up X-Forwarded-For {remote_host}
            transport http {
              tls
              tls_insecure_skip_verify
            }
          }
        }

        @dns host dns.laufin.xyz
        handle @dns {
          reverse_proxy http://192.168.2.50:5380
        }

        @wikipedia host wikipedia.laufin.xyz
        handle @wikipedia {
          reverse_proxy http://192.168.2.50:8012
        }

        @immich host immich.laufin.xyz
        handle @immich {
          reverse_proxy http://192.168.2.50:2283
        }

        @share host share.laufin.xyz
        handle @share {
          reverse_proxy http://192.168.2.50:8087
        }

        @omni-tools host omni-tools.laufin.xyz
        handle @omni-tools {
          reverse_proxy http://192.168.2.50:8086
        }

        @mazanoke host mazanoke.laufin.xyz
        handle @mazanoke {
          reverse_proxy http://192.168.2.50:3474
        }

        @dns2 host dns2.laufin.xyz
        handle @dns2 {
          reverse_proxy http://192.168.2.207:5380
        }

        @wallos host wallos.laufin.xyz
        handle @wallos {
          reverse_proxy http://192.168.2.50:8282
        }

        @stirling-pdf host stirling-pdf.laufin.xyz
        handle @stirling-pdf {
          reverse_proxy http://192.168.2.50:7080
        }

        @morphos host morphos.laufin.xyz
        handle @morphos {
          reverse_proxy http://192.168.2.50:7090
        }

        @jellyseer host jellyseer.laufin.xyz
        handle @jellyseer {
          reverse_proxy http://192.168.2.50:5055
        }

        @manga host manga.laufin.xyz
        handle @manga {
          reverse_proxy http://192.168.2.50:4568
        }

        @todo host todo.laufin.xyz
        handle @todo {
          reverse_proxy http://192.168.2.50:1337
        }

        @search host search.laufin.xyz
        handle @search {
          reverse_proxy http://192.168.2.50:8882
        }

        @it-tools host it-tools.laufin.xyz
        handle @it-tools {
          reverse_proxy http://192.168.2.50:8384
        }

        @home host home.laufin.xyz
        handle @home {
          reverse_proxy http://192.168.2.50:3311
        }

        @prowlarr host prowlarr.laufin.xyz
        handle @prowlarr {
          reverse_proxy http://192.168.2.50:9696
        }

        @qbittorrent host qbittorrent.laufin.xyz
        handle @qbittorrent {
          reverse_proxy http://192.168.2.50:8082
        }

        @radarr host radarr.laufin.xyz
        handle @radarr {
          reverse_proxy http://192.168.2.50:7878
        }

        @sonarr host sonarr.laufin.xyz
        handle @sonarr {
          reverse_proxy http://192.168.2.50:8989
        }

        @jellyfin host jellyfin.laufin.xyz
        handle @jellyfin {
          reverse_proxy http://192.168.2.50:8096
        }

        @gatus host gatus.laufin.xyz
        handle @gatus {
          reverse_proxy http://192.168.2.50:8080
        }

        @ntfy host ntfy.laufin.xyz http://ntfy.laufin.xyz
        handle @ntfy {
          reverse_proxy http://192.168.2.50:8081 {
            header_up Host {http.reverse_proxy.upstream.hostport}
          }
          @httpget {
            protocol http
            method GET
            path_regexp ^/([-_a-z0-9]{0,64}$|docs/|static/)
          }
          redir @httpget https://{host}{uri}
        }

        @kavita host kavita.laufin.xyz
        handle @kavita {
          reverse_proxy http://192.168.2.50:5000
        }

        @karakeep host karakeep.laufin.xyz
        handle @karakeep {
          reverse_proxy http://192.168.2.50:3050
        }

        @rss host rss.laufin.xyz
        handle @rss {
          reverse_proxy http://192.168.2.50:8085
        }

        @matrix-admin host matrix-admin.laufin.xyz
        handle @matrix-admin {
          reverse_proxy http://192.168.2.50:7373
        }

        @recommendarr host recommendarr.laufin.xyz
        handle @recommendarr {
          reverse_proxy http://192.168.2.50:3007
        }

        @bazarr host bazarr.laufin.xyz
        handle @bazarr {
          reverse_proxy http://192.168.2.50:6767
        }
      }
    '';
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785"
      ];
      hash = "sha256-/P7oQc5Sy8kvfezX9DsnUgQJ7d33HOLJUULhXA+NLXY=";
    };
    configFile = caddyfile;
    group = "tankusers";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
