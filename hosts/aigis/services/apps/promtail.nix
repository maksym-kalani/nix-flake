{ config, pkgs, lib, ... }:
let
  port = 3101;
  lokiUrl = "http://127.0.0.1:3100";
in
{
  services.promtail = {
    enable = true;
    # built-in module will generate a systemd service for promtail:
    configuration = {
      server.http_listen_port = port;
      positions.filename = "/var/lib/promtail/positions.yaml";
      clients = [
        # push to the local Loki
        { url = "${lokiUrl}/loki/api/v1/push"; }
      ];
      scrape_configs = [
        {
          job_name = "systemd-journal";
          journal = {
            labels = {
              job = "systemd-journal";
            };
            # how far back to read on restart:
            max_age = "12h";
          };
          relabel_configs = [
            {
              # keep the systemd unit name
              source_labels = [ "__journal__SYSTEMD_UNIT" ];
              target_label   = "unit";
            }
          ];
        }
        {
          job_name = "zfs-zed";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "zfs-zed";
                __path__ = "/var/log/zed.debug.log";
              };
            }
          ];
        }
        {
          job_name = "zpool-events";
          journal = {
            labels = {
              job = "zpool-events";
              SYSLOG_IDENTIFIER = "zpool-events";
            };
          };
        }
      ];
    };
  };
  
  systemd.tmpfiles.rules = [
    "d /var/lib/promtail 0755 promtail promtail -"
  ];

}