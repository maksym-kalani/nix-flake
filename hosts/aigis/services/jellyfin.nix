{
  lib,
  ...
}: let
  name = "jellyfin";
  port = 8096;
in {
  services.jellyfin.enable = true;
  users.users.jellyfin.extraGroups = ["tankusers" "render" "video"];

  networking.firewall.allowedTCPPorts = [port];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Jellyfin";
      url = "jellyfin.laufin.xyz";
      icon = "television";
      inherit port;
      gatusName = name;
    })
  ];
}
