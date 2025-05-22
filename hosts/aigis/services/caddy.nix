{ config, pkgs, ... }:
{
   services.caddy = {
     enable = true;
     package = pkgs.caddy.withPlugins {
       plugins = [ "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785" ];
       hash = "sha256-VOPxBx0GvgidMXmt2UvVUTIT6yqF7HxeI4FT9+vk+pk=";
     };

     virtualHosts."*.mydomain.com".extraConfig = ''
       tls {
         dns namecheap {
           api_key {env.NAMECHEAP_API_KEY}
           user    {env.NAMECHEAP_API_USER}
         }
       }
       reverse_proxy 127.0.0.1:8080
     '';
   };

   networking.firewall.allowedTCPPorts = [ 80 443 ];
 }