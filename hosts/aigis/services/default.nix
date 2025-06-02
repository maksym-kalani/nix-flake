{
  imports = [
    ./containers
    ./apps
    ./caddy.nix
    ./podman.nix
    ./wireguard.nix
    ./samba.nix
    ./update-containers.nix
    ./restart-containers.nix
  ];
}