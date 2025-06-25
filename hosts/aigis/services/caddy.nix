{ config, pkgs, ... }:
{
  services.caddy = {
   enable = true;
   package = pkgs.caddy.withPlugins {
     plugins = [ "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785" ];
     hash = "sha256-VOPxBx0GvgidMXmt2UvVUTIT6yqF7HxeI4FT9+vk+pk=";
   };
   configFile = "/mnt/tank/appdata/caddy/Caddyfile";
   group = "tankusers";
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}