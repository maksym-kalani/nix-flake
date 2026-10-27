{
  lib,
  ...
}:
let
  name = "jellyfin";
  port = 8096;
in
{
  services.jellyfin.enable = true;
  users.users.jellyfin.extraGroups = [
    "tankusers"
    "render"
    "video"
  ];

  networking.firewall.allowedTCPPorts = [ port ];
  networking.firewall.allowedUDPPorts = [ 7359 ]; # client discovery

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Jellyfin";
      url = "jellyfin.laufin.xyz";
      icon = "television";
      inherit port;
      healthPath = "/health";
      healthConditions = [ "[BODY] == Healthy" ];
      gatusName = name;
    })
  ];
}
