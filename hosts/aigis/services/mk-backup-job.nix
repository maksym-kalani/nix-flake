{ pkgs }:
{ name, src, dest, schedule ? "*-*-* 04:00:00" }:
{
  systemd.services."${name}-backup" = {
    description = "Backup ${name} data";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.rsync}/bin/rsync -a --delete ${src} ${dest}";
      User = "root";
      Group = "root";
    };
  };

  systemd.timers."${name}-backup" = {
    description = "Run ${name} backup";
    wantedBy = [ "timers.target" ];
    requires = [ "${name}-backup.service" ];
    timerConfig = {
      OnCalendar = schedule;
      Persistent = true;
    };
  };
}
