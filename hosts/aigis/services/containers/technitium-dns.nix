{ lib, config, ... }:

let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  appdata = "/mnt/tank/appdata/";
  # Configuration options with defaults
  cfg = {
    # Container name
    name = "dns";
    
    # Container image
    image = "technitium/dns-server:latest";
    
    # Container port configuration
    port = {
      internal = 5380; # Port inside the container
      external = 5380; # Port on the host
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
      "${appdata}${cfg.name}:/etc/dns"
      
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
      DNS_SERVER_DOMAIN = "aigis-dns-server";
      DNS_SERVER_ENABLE_BLOCKING = "true";
      DNS_SERVER_BLOCK_LIST_URLS = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_49.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt, https://www.awwwwesome.org/url-blocklist/url-blocklist.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt, https://blocklistproject.github.io/Lists/adguard/tracking-ags.txt, https://blocklistproject.github.io/Lists/adguard/ads-ags.txt, https://raw.githubusercontent.com/deathbybandaid/piholeparser/master/Subscribable-Lists/CountryCodesLists/Ukraine.txt";
      DNS_SERVER_FORWARDERS = "9.9.9.10, 8.8.8.8, 149.112.112.10";
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
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}" "53:53/udp" "53:53/tcp"];
    
    # Optional configs
    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };
  
  networking.firewall.allowedTCPPorts = [ cfg.port.external 53 ];
  
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