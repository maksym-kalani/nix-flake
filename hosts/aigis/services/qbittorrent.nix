{
  lib,
  ...
}: let
  appdata = "/var/lib/containers/";
  UID = 888;
  GID = 990;
  cfg = {
    name = "qbittorrent";

    image = "lscr.io/linuxserver/qbittorrent@sha256:8d48fa8c619caadfb103f04efea8747e2a2762d6c7551690919cffb987e61cee"; # pinned to what aigis ran on 2026-10-27

    port = {
      internal = 8082;
      external = 8082;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}:/config"
      "/mnt/tank/media/downloads:/mnt/tank/media/downloads"
      "/mnt/incomplete:/mnt/incomplete"

    ];
    environmentVariables = {
      WEBUI_PORT = "${toString cfg.port.external}";
      UMASK = "0002";
      TZ = "Europe/Kyiv";
      PUID = "${toString UID}";
      PGID = "${toString GID}";
    };

    autoStart = true;
  };
in {
  users.users = {
    pod-qbittorrent = {
      isSystemUser = true;
      uid = UID;
      group = "tankusers";
    };
  };
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = [
      "${toString cfg.port.external}:${toString cfg.port.internal}"
      "6881:6881"
      "6881:6881/udp"
    ];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };

  networking.firewall.allowedTCPPorts = [cfg.port.external 6881];
  networking.firewall.allowedUDPPorts = [6881];

  systemd.tmpfiles.rules = ["d ${appdata}${cfg.name} :0755 :root :root -"];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "QBittorrent";
      url = "qbittorrent.laufin.xyz";
      icon = "download-circle-outline";
      port = cfg.port.external;
      gatusName = cfg.name;
    })
  ];
}
