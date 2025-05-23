# ntfy.nix
{ config, pkgs, ... }:

{
  services.ntfy-sh.enable = true;
  services.ntfy-sh.settings = {
    base-url = "http://192.168.2.50";
    listen-http = ":8081";
  };
  
  networking.firewall.allowedTCPPorts = [ 8081 ];
}
