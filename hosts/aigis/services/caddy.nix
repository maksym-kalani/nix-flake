{ config, pkgs, ... }:
{
  services.caddy = {
   enable = true;
   package = pkgs.caddy.withPlugins {
     plugins = [ "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785" ];
     hash = "sha256-6AiQ8kb/1JN/ZG32bJaSYYTgFnGgrfNZ46atr11bPTc=";
   };
   configFile = "/var/lib/caddy/Caddyfile";
   group = "tankusers";
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
