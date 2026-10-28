{
  lib,
  ...
}:
let
  appdata = "/var/lib/containers/";
  UID = 888;
  GID = 990;
  cfg = {
    name = "qbittorrent";

    image = "lscr.io/linuxserver/qbittorrent@sha256:75ecbb1c89ab7b0a21c4bde40b4820e4f1649d2d56d83b91913422155e8d2a5f";

    port = {
      internal = 8082;
      external = 8082;
    };

    extraOptions = [ ];
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
in
{
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

  networking.firewall.allowedTCPPorts = [
    cfg.port.external
    6881
  ];
  networking.firewall.allowedUDPPorts = [ 6881 ];

  systemd.tmpfiles.rules = [ "d ${appdata}${cfg.name} :0755 :root :root -" ];

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
