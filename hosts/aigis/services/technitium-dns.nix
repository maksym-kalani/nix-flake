{
  lib,
  ...
}: let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "dns";

    image = "docker.io/technitium/dns-server@sha256:3580381de00ba316748abced1ad0f942aff5a625993fa5dee22a902e26d2c524"; # pinned to what aigis ran on 2026-10-27

    port = {
      internal = 5380;
      external = 5380;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}:/etc/dns"
    ];
    environmentVariables = {
      DNS_SERVER_DOMAIN = "aigis-dns-server";
      DNS_SERVER_ENABLE_BLOCKING = "true";
      # Bootstrap only: an existing /etc/dns config must be updated via the web UI/API.
      # HaGeZi Pro covers ads/trackers; TIF Medium adds threat intelligence.
      DNS_SERVER_BLOCK_LIST_URLS = lib.concatStringsSep "," [
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro-onlydomains.txt"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.medium-onlydomains.txt"
      ];
      DNS_SERVER_FORWARDERS = "9.9.9.10, 8.8.8.8, 149.112.112.10";
    };

    autoStart = true;
  };
in {
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Technitium DNS";
      url = "dns.laufin.xyz";
      icon = "shield";
      port = cfg.port.external;
      gatusName = cfg.name;
    })
  ];

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}" "53:53/udp" "53:53/tcp"];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };

  networking.firewall.allowedTCPPorts = [cfg.port.external 53];
  networking.firewall.allowedUDPPorts = [53];

  systemd.tmpfiles.rules = ["d ${appdata}${cfg.name} :0755 :root :root -"];
}
