# In your host configuration file
{ config, pkgs, ... }: {
  # Your existing config...
  
  nixarr = {
    enable = true;
    mediaUsers = ["media"];
    
    jellyfin.enable = true;
    transmission.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;
    jellyseerr.enable = true;
  };
}
