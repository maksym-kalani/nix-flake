{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.qbittorrent;
  name = "qbittorrent";
  port = 8082;
  UID = 888;
  GID = 990;
in {
  options.server.services.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent torrent client";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      users.users.pod-qbittorrent = {
        isSystemUser = true;
        uid = UID;
        group = "tankusers";
      };

      virtualisation.oci-containers.containers.${name} = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        ports = [
          "${toString port}:8082"
          "6881:6881"
          "6881:6881/udp"
        ];
        volumes = [
          "${config.server.containerData}/${name}:/config"
          "/mnt/tank/media/downloads:/mnt/tank/media/downloads"
          "/mnt/incomplete:/mnt/incomplete"
        ];
        environment = {
          WEBUI_PORT = toString port;
          UMASK = "0002";
          TZ = "Europe/Kyiv";
          PUID = toString UID;
          PGID = toString GID;
        };
        autoStart = true;
      };

      networking.firewall.allowedTCPPorts = [ 6881 ];
      networking.firewall.allowedUDPPorts = [ 6881 ];
    }
  ]);
}
