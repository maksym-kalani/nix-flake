{ config, pkgs, ... }:
{
  services.caddy = {
   enable = true;
   package = pkgs.caddy.withPlugins {
     plugins = [ "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785" ];
     hash = "sha256-znCY7j6QXjMOsCBfcQc05f9LW4Wm+idEDdoS8lG2gEM=";
   };
   configFile = "/var/lib/caddy/Caddyfile";
   group = "tankusers";
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
