# dashy.nix
{ lib, config, pkgs, ... }:

let
  domain = "laufin.xyz";
  ip = "192.168.2.50";
  appdata = "/mnt/tank/appdata/";
  cfg = {
    name = "dashy";
    image = "lissy93/dashy:latest";
    port = {
      internal = 8080;
      external = 4000;
    };
    volumes = [
      "${appdata}dashy/conf.yml:/app/user-data/conf.yml"
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
  - name: Media Management
    icon: fas fa-film
    items:
      - title: Jellyfin
        description: Media server for movies, TV shows, and music
        icon: fas fa-play
        url: https://jellyfin.laufin.xyz
        statusCheck: true
        
      - title: Kavita
        description: Digital book library for manga, comics, and e-books
        icon: fas fa-book
        url: https://kavita.laufin.xyz
        statusCheck: true
        
      - title: Tachidesk
        description: Manga reader and downloader
        icon: fas fa-book-open
        url: https://tachidesk.laufin.xyz
        statusCheck: true

  - name: Download Management
    icon: fas fa-download
    items:
      - title: qBittorrent
        description: Torrent client for downloading files
        icon: fas fa-magnet
        url: https://qbittorrent.laufin.xyz
        statusCheck: true
        
      - title: Radarr
        description: Movie collection manager and automation
        icon: fas fa-film
        url: https://radarr.laufin.xyz
        statusCheck: true
        
      - title: Sonarr
        description: TV show collection manager and automation
        icon: fas fa-tv
        url: https://sonarr.laufin.xyz
        statusCheck: true
        
      - title: Prowlarr
        description: Indexer manager/proxy for media managers
        icon: fas fa-search
        url: https://prowlarr.laufin.xyz
        statusCheck: true

  - name: Utilities
    icon: fas fa-tools
    items:
      - title: Stirling PDF
        description: Powerful PDF manipulation tools
        icon: fas fa-file-pdf
        url: https://stirling-pdf.laufin.xyz
        statusCheck: true
        
      - title: IT Tools
        description: Collection of useful IT and development tools
        icon: fas fa-laptop-code
        url: https://it-tools.laufin.xyz
        statusCheck: true
        
      - title: Technitium DNS
        description: DNS server with ad-blocking capabilities
        icon: fas fa-server
        url: https://technitium-dns.laufin.xyz
        statusCheck: true
        
      - title: SearXNG
        description: Privacy-focused metasearch engine
        icon: fas fa-search
        url: https://searxng.laufin.xyz
        statusCheck: true

  - name: System Services
    icon: fas fa-server
    items:
      - title: Ntfy
        description: Notification service
        icon: fas fa-bell
        url: https://ntfy.laufin.xyz
        statusCheck: true
        
      - title: Commafeed
        description: RSS Feed Reader
        icon: fas fa-rss
        url: https://commafeed.laufin.xyz
        statusCheck: true
        
      - title: Wallos
        description: Subscription management and tracking
        icon: fas fa-credit-card
        url: https://wallos.laufin.xyz
        statusCheck: true
        
      - title: MorphOS
        description: System management interface
        icon: fas fa-cogs
        url: https://morphos.laufin.xyz
        statusCheck: true

  - name: Monitoring
    icon: fas fa-chart-line
    items:
      - title: Gatus
        description: Status page and service monitoring
        icon: fas fa-heartbeat
        url: https://gatus.laufin.xyz
        statusCheck: true
        
      - title: Home
        description: This dashboard
        icon: fas fa-home
        url: https://home.laufin.xyz
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
    "home.${domain}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port.external} {
          header_up Host {http.reverse_proxy.upstream.hostport}
        }
      '';
    };
  };
}