{
  pkgs,
  ...
}:
{
  # ZFS Event Daemon (ZED) → writes events to its debug log & syslog
  systemd.services."zfs-zed".enable = true;
  services.zfs.zed.settings = {
    # where ZED writes its debug output
    ZED_DEBUG_LOG = "/var/log/zed.debug.log";
    # how often to batch notifications
    ZED_NOTIFY_INTERVAL_SECS = "3600";
    # include full event details
    ZED_NOTIFY_VERBOSE = "true";
  };

  systemd.services.zpool-events = {
    description = "Stream zpool events into journald";
    after = [ "zfs-import.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.zfs}/bin/zpool events -f";
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "zpool-events";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
