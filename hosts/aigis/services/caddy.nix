{ config, pkgs, ... }:
{
  services.caddy = {
   enable = false;
   package = pkgs.caddy.withPlugins {
     plugins = [ "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785" ];
     hash = "sha256-VOPxBx0GvgidMXmt2UvVUTIT6yqF7HxeI4FT9+vk+pk=";
   };

    globalConfig = ''
    '';
    
   virtualHosts = 
    {
      "portainer.laufin.xyz" = {
        extraConfig = ''
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
        '';
      };
      "dns2.laufin.xyz" = {
        extraConfig = ''
          reverse_proxy http://192.168.2.207:5380
        '';
      };
      "todo.laufin.xyz" = {
        extraConfig = ''
          reverse_proxy http://192.168.2.201:1337
        '';
      };
      "git.laufin.xyz" = {
        extraConfig = ''
          reverse_proxy http://192.168.2.201:3443
        '';
      };
      "matrix-admin.laufin.xyz" = {
        extraConfig = ''
          reverse_proxy http://192.168.2.201:7373
        '';
      };
    };
  };
  
  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.sops.secrets.namecheap_api_user.path
    config.sops.secrets.namecheap_api_key.path
  ];
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}