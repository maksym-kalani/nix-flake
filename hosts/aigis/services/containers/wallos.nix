{ lib, config, ... }:

let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  appdata = "/mnt/tank/appdata/";
  # Configuration options with defaults
  cfg = {
    # Container name
    name = "wallos";
    
    # Container image
    image = "bellamy/wallos:latest";
    
    # Container port configuration
    port = {
      internal = 80; # Port inside the container
      external = 8282; # Port on the host
    };
    
    # Optional settings with defaults
    extraOptions = [
      # Resource constraints
      #"--memory=512m"
      #"--cpus=2"
      
      # Network settings
      #"--network=host"
      
      # Security options
      #"--cap-drop=ALL"
      #"--cap-add=NET_BIND_SERVICE"
      
      # Health check
      #"--health-cmd=curl -f http://localhost/ || exit 1"
      #"--health-interval=30s"
      
      # Labels
      #"--label=com.example.description=Web server"
    ];
    volumes = [
      # Simple host:container path mapping
      "${appdata}${cfg.name}/db:/var/www/html/db"
      "${appdata}${cfg.name}/logos:/var/www/html/images/uploads/logos"
      
      # Configuration with read-only flag
      #"/config/files:/etc/nginx/conf.d:ro"
      
      # Named volume
      #"nginx-data:/var/www/html"
      
      # Bind mount with specific options
      #"/var/log/nginx:/var/log/nginx:Z"
    ];
    environmentVariables = {
      # Simple key-value pairs
      #NGINX_HOST = "example.com";
      #NGINX_PORT = "80";
      TZ = "Europe/Kyiv";
      
      # Toggle features
      #ENABLE_GZIP = "true";
      #DEBUG_MODE = "false";
    };
    
    # Run settings
    autoStart = true;
  };
in {
  # Container definition
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];
    
    # Optional configs
    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };
  
  networking.firewall.allowedTCPPorts = [ cfg.port.external ];
  
  services.gatus.settings.endpoints = [
    {
      name      = cfg.name;
      url       = "http://${ip}:${toString cfg.port.external}";
      interval  = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${cfg.name} health check";
          failure-threshold = 3;
          success-threshold = 2;
        }
      ];
    }
  ];
  
  services.caddy.virtualHosts = 
  {
    "${cfg.name}.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port.external}
      '';
    };
  };
}