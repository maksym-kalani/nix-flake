{ lib, config, ... }:

let
  # Configuration options with defaults
  cfg = {
    # Container name
    name = "commafeed";
    
    # Container image
    image = "athou/commafeed:latest-h2";
    
    # Container port configuration
    port = {
      internal = 8082; # Port inside the container
      external = 8552; # Port on the host
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
      #"/path/on/host:/path/in/container"
      
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
  
  services.gatus.settings.endpoints = [
    {
      name      = cfg.name;
      url       = "http://192.168.2.50:${toString cfg.port.external}";
      interval  = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
    }
  ];
}