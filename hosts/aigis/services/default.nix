{
  imports = [
    ./containers
    ./apps
    ./caddy.nix
    ./podman.nix
    ./wireguard.nix
    ./samba.nix
    ./ntfy-on-ssh.nix
    ./restic-backup.nix
  ];
}
