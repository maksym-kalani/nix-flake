{ inputs, outputs, ... }:
{
  imports = [
    ../common
    ./configuration.nix
    ./zfs-logging.nix

    # Import the modules
    ../../modules

    # System services (not refactored)
    ./services/caddy.nix
    ./services/podman.nix
    ./services/wireguard.nix
    ./services/samba.nix
    ./services/ntfy-on-ssh.nix
    ./services/restic-backup.nix
    ./services/health-monitor.nix
  ];

  # Server configuration - all in one place
  server = {
    ip = "192.168.2.50";
    domain = "laufin.xyz";
    appdata = "/mnt/tank/appdata";
    containerData = "/var/lib/containers";
  };

  # Enable services declaratively
  server.services = {
    # Core services
    gatus.enable = true;
    ntfy.enable = true;

    # Media services
    jellyfin.enable = true;
    jellyseerr.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;
    immich.enable = true;

    # Productivity
    karakeep.enable = true;
    vikunja.enable = true;

    # Reading
    kavita.enable = true;
    tachidesk.enable = true;
    kiwix.enable = true;

    # Containers
    fusion.enable = true;
    morphos.enable = true;
    searxng.enable = true;
    technitium-dns.enable = true;
    qbittorrent.enable = true;
    it-tools.enable = true;
    wallos.enable = true;
    stirling-pdf.enable = true;
    omni-tools.enable = true;
    mazanoke.enable = true;
    local-content-share.enable = true;
    flame-homepage.enable = true;
    recommendarr.enable = true;
    matrix-admin.enable = true;
    commafeed.enable = true;

    # Home Assistant support
    piper.enable = true;
    whisper.enable = true;
    hass-mariadb.enable = true;
  };

  services.podman.enable = true;
}
