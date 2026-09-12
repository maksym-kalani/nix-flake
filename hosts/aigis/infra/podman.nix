{
  pkgs,
  ...
}: let
  podman-update-all = pkgs.writeShellScriptBin "podman-update-all" ''
    set -euo pipefail

    sudo systemctl list-units --type=service --all --no-legend --plain 'podman-*' | awk '{print $1}' \
      | while read -r unit; do
          name="''${unit#podman-}"; name="''${name%.service}"
          image=$(sudo podman inspect "$name" --format '{{.ImageName}}' 2>/dev/null) || continue
          echo "==> $name ($image)"
          sudo podman pull "$image" && sudo systemctl restart "$unit"
        done
  '';
in {
  virtualisation = {
    containers.registries.settings.unqualified-search-registries = ["docker.io"];

    podman = {
      enable = true;
      dockerCompat = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [
          "--filter=until=24h"
          "--filter=label!=important"
        ];
      };
      defaultNetwork.settings.dns_enabled = false;
    };
  };
  environment.systemPackages = with pkgs; [
    podman-compose
    podman-update-all
  ];
}
