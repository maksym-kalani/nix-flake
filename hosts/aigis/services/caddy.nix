{ config, pkgs, ... }:
{
  services.caddy = {
   enable = true;
   package = pkgs.caddy.withPlugins {
     plugins = [ "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785" ];
     hash = "sha256-VOPxBx0GvgidMXmt2UvVUTIT6yqF7HxeI4FT9+vk+pk=";
   };
  
   globalConfig = ''
     acme_dns namecheap {
       api_key {env.NAMECHEAP_API_KEY}
       user    {env.NAMECHEAP_API_USER}
       api_endpoint https://api.namecheap.com/xml.response
     }
    '';
  };
  
  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.sops.secrets.namecheap_api_user.path
    config.sops.secrets.namecheap_api_key.path
  ];
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
 }