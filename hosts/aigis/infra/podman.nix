{
  pkgs,
  ...
}:
{
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
  ];
}
