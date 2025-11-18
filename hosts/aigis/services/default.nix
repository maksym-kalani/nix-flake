{
  imports = [
    ./containers
    ./apps
    ./caddy.nix
    ./podman.nix
    ./wireguard.nix
    ./samba.nix
    #./update-containers.nix
    #./restart-containers.nix
    ./ntfy-on-ssh.nix
    ./restic-backup.nix
    ./health-monitor.nix
    #./mk-backup-job.nix
  ];
}