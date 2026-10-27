{
  pkgs,
  ...
}:
{
  systemd.services."zfs-zed".enable = true;
  services.zfs.zed.settings = {
    ZED_DEBUG_LOG = "/var/log/zed.debug.log";
    ZED_NOTIFY_INTERVAL_SECS = "3600";
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
