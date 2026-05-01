{
  config,
  pkgs,
  ...
}:
#add restic init if running first time
let
  restic_backup = pkgs.writeShellScriptBin "restic-backup" ''
    set -euo pipefail
    SOURCES=(
      /mnt/tank/appdata
      /mnt/tank/media/ttrpgs
      /mnt/tank/users
      /var/lib/containers
      /var/lib/jellyfin
      /var/lib/karakeep
      /var/lib/prowlarr
      /var/lib/radarr
      /var/lib/sonarr
      /var/lib/vikunja
      /var/lib/immich
      /var/lib/caddy
      /var/lib/bazarr
    )

    # 1) Run the backup
    restic backup -v "''${SOURCES[@]}" \
      --verbose \
      --tag zfs-share

    # 2) Forget/prune old snapshots (e.g. keep 7 daily, 4 weekly, 6 monthly)
    restic forget -v \
      --prune \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 6 \
      --tag zfs-share
  '';
in
{
  environment.systemPackages = [ restic_backup ];

  systemd.services.restic-zfs-backup = {
    description = "Restic backup of ZFS folders to Hetzner";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
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
      # Every Friday at 03:00 local time
      OnCalendar = "Fri *-*-* 03:00:00";
      Persistent = true;
    };
  };
}
