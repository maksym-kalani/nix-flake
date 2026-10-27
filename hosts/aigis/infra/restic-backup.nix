{
  config,
  pkgs,
  ...
}:
# run `restic init` once before the first backup
let
  restic_backup = pkgs.writeShellScriptBin "restic-backup" ''
    set -euo pipefail
    SOURCES=(
      /mnt/tank/media/ttrpgs
      /mnt/tank/media/photos
      /mnt/tank/users
      /var/lib/containers
      /var/lib/suwayomi-server
      /var/lib/jellyfin
      /var/lib/kavita
      /var/lib/karakeep
      /var/lib/private/prowlarr
      /var/lib/radarr
      /var/lib/sonarr
      /var/lib/private/vikunja
      /var/lib/immich
      /var/lib/caddy
      /var/lib/postgresql
      /var/lib/private/ntfy-sh
      /var/lib/private/local-content-share
      /var/lib/private/flame
      /var/lib/samba
      /etc/NetworkManager/system-connections
      /etc/wireguard/server.key
      /etc/ssh/ssh_host_*
      /srv/kiwix
    )

    # no -v, so journald keeps the real errors; overlay merged dirs are live mount views
    restic backup "''${SOURCES[@]}" \
      --exclude '/var/lib/containers/storage/overlay/*/merged' \
      --tag zfs-share

    restic forget -v \
      --prune \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 6 \
      --tag zfs-share
  '';
in
{
  sops.secrets = {
    restic_repo = { };
    restic_password = { };
  };

  environment.systemPackages = [ restic_backup ];

  systemd.services.restic-zfs-backup = {
    description = "Restic backup of ZFS folders to Hetzner";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Environment = [
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
      OnCalendar = "Fri *-*-* 03:00:00";
      Persistent = true;
    };
  };
}
