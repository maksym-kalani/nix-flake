{
  config,
  lib,
  pkgs,
  ...
}:
let
  restic_backup = pkgs.writeShellScriptBin "restic-backup" 
     ''
     #!/usr/bin/env bash
     set -euo pipefail
     SOURCES=(
       /mnt/tank/appdata
       /mnt/tank/media/ttrpgs
       /mnt/tank/users
     )
     
     # 1) Run the backup
     restic backup "''${SOURCES[@]}" \
       --verbose \
       --tag zfs-share
     
     # 2) Forget/prune old snapshots (e.g. keep 7 daily, 4 weekly, 6 monthly)
     restic forget \
       --prune \
       --keep-daily 7 \
       --keep-weekly 4 \
       --keep-monthly 6 \
       --tag zfs-share
   '';
in
{
  environment.systemPackages = [restic_backup];

  systemd.services.restic-zfs-backup = {
    description = "Restic backup of ZFS folders to Hetzner";
    wants       = [ "network-online.target" ];
    after       = [ "network-online.target" ];
    serviceConfig = {
      Type        = "oneshot";
      User = "maksym";
      Environment = [
        # point PATH at the active system profile
        "PATH=/run/current-system/sw/bin:$PATH"
      ];
      EnvironmentFile = [ 
        config.sops.secrets.restic_repo.path
        config.sops.secrets.restic_password.path 
      ];
      ExecStart = "${restic_backup}/bin/restic-backup";
    };
  };
  
  systemd.timers.restic-zfs-backup = {
    description = "Weekly Restic → ZFS share backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Every Sunday at 03:00 local time
      OnCalendar   = "Sun *-*-* 03:00:00";
      Persistent = true;
    };
  };
}