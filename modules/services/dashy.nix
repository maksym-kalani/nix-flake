{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.dashy;
  name = "dashy";
  port = 4000;
in {
  options.server.services.dashy = {
    enable = lib.mkEnableOption "Dashy dashboard";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; subdomain = "home"; extraCaddyConfig = ''
      reverse_proxy 127.0.0.1:${toString port} {
        header_up Host {http.reverse_proxy.upstream.hostport}
      }
    ''; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "lissy93/dashy:latest";
        ports = [ "${toString port}:8080" ];
        volumes = [
          "${config.server.appdata}/dashy/conf.yml:/app/user-data/conf.yml"
        ];
        autoStart = true;
      };

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
        url: https://jellyfin.${config.server.domain}
        statusCheck: true

      - title: Kavita
        description: Digital book library for manga, comics, and e-books
        icon: fas fa-book
        url: https://kavita.${config.server.domain}
        statusCheck: true

      - title: Tachidesk
        description: Manga reader and downloader
        icon: fas fa-book-open
        url: https://tachidesk.${config.server.domain}
        statusCheck: true

  - name: Download Management
    icon: fas fa-download
    items:
      - title: qBittorrent
        description: Torrent client for downloading files
        icon: fas fa-magnet
        url: https://qbittorrent.${config.server.domain}
        statusCheck: true

      - title: Radarr
        description: Movie collection manager and automation
        icon: fas fa-film
        url: https://radarr.${config.server.domain}
        statusCheck: true

      - title: Sonarr
        description: TV show collection manager and automation
        icon: fas fa-tv
        url: https://sonarr.${config.server.domain}
        statusCheck: true

      - title: Prowlarr
        description: Indexer manager/proxy for media managers
        icon: fas fa-search
        url: https://prowlarr.${config.server.domain}
        statusCheck: true

  - name: Utilities
    icon: fas fa-tools
    items:
      - title: Stirling PDF
        description: Powerful PDF manipulation tools
        icon: fas fa-file-pdf
        url: https://stirling-pdf.${config.server.domain}
        statusCheck: true

      - title: IT Tools
        description: Collection of useful IT and development tools
        icon: fas fa-laptop-code
        url: https://it-tools.${config.server.domain}
        statusCheck: true

      - title: Technitium DNS
        description: DNS server with ad-blocking capabilities
        icon: fas fa-server
        url: https://dns.${config.server.domain}
        statusCheck: true

      - title: SearXNG
        description: Privacy-focused metasearch engine
        icon: fas fa-search
        url: https://search.${config.server.domain}
        statusCheck: true

  - name: System Services
    icon: fas fa-server
    items:
      - title: Ntfy
        description: Notification service
        icon: fas fa-bell
        url: https://ntfy.${config.server.domain}
        statusCheck: true

      - title: Commafeed
        description: RSS Feed Reader
        icon: fas fa-rss
        url: https://commafeed.${config.server.domain}
        statusCheck: true

      - title: Wallos
        description: Subscription management and tracking
        icon: fas fa-credit-card
        url: https://wallos.${config.server.domain}
        statusCheck: true

      - title: MorphOS
        description: System management interface
        icon: fas fa-cogs
        url: https://morphos.${config.server.domain}
        statusCheck: true

  - name: Monitoring
    icon: fas fa-chart-line
    items:
      - title: Gatus
        description: Status page and service monitoring
        icon: fas fa-heartbeat
        url: https://gatus.${config.server.domain}
        statusCheck: true

      - title: Home
        description: This dashboard
        icon: fas fa-home
        url: https://home.${config.server.domain}
        statusCheck: true
EOF
        fi
        chmod 644 /var/lib/dashy/conf.yml
      '';
    }
  ]);
}
