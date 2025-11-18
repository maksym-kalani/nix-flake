{ config, lib, pkgs, ... }:
{
  # Install the script to /etc to mirror zfs-health-check pattern
  environment.etc."health-monitor.sh".text = builtins.readFile ./health-monitor.sh;
  environment.etc."health-monitor.sh".mode = "0755";

  # Ensure required tools are available for the script
  environment.systemPackages = with pkgs; [
    coreutils
    procps
    bc
    gnugrep
    gawk
    curl
    sysstat  # provides iostat
    zfs
  ];

  # Oneshot service executing the script
  systemd.services."health-monitor" = {
    description = "System Health Monitor with ntfy Alerts";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/health-monitor.sh";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Timer that runs the service periodically (hourly, persistent), like zfs-health-check
  systemd.timers."health-monitor" = {
    description = "Run health monitor periodically";
    wantedBy   = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      Unit = "health-monitor.service";
    };
  };
}