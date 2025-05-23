# dashy.nix
{ lib, config, pkgs, ... }:

let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  cfg = {
    name = "dashy";
    image = "lissy93/dashy:latest";
    port = {
      internal = 8080;
      external = 4000;
    };
    volumes = [
      "/var/lib/dashy/conf.yml:/app/user-data/conf.yml"
    ];
    autoStart = true;
  };
in {
  # Container definition
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];
    volumes = cfg.volumes;
    autoStart = cfg.autoStart;
  };
  
  # Create initial configuration file if it doesn't exist
  system.activationScripts.dashyConfig = ''
    mkdir -p /var/lib/dashy
    if [ ! -f /var/lib/dashy/conf.yml ]; then
      cat > /var/lib/dashy/conf.yml << EOF
# Dashy Configuration File

# Page meta info
pageInfo:
  title: Home Dashboard
  description: Your personal services dashboard
  navLinks:
    - title: GitHub
      path: https://github.com/

# Main content sections
sections:
  - name: System Services
    icon: fas fa-server
    items:
      - title: Ntfy
        description: Notification service
        icon: fas fa-bell
        url: https://ntfy.${domain}
        statusCheck: true
        
      - title: Commafeed
        description: RSS Feed Reader
        icon: fas fa-rss
        url: https://commafeed.${domain}
        statusCheck: true

  - name: Monitoring
    icon: fas fa-chart-line
    items:
      - title: Gatus
        description: Status page
        icon: fas fa-heartbeat
        url: https://gatus.${domain}
        statusCheck: true
EOF
    fi
    chmod 644 /var/lib/dashy/conf.yml
  '';
  
  networking.firewall.allowedTCPPorts = [ cfg.port.external ];
  
  services.gatus.settings.endpoints = [
    {
      name      = cfg.name;
      url       = "http://${ip}:${toString cfg.port.external}";
      interval  = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
    }
  ];
  
  services.caddy.virtualHosts = 
  {
    "${cfg.name}.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port.external} {
          header_up Host {http.reverse_proxy.upstream.hostport}
        }
      '';
    };
  };
}