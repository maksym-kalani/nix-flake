{
  lib,
  ...
}:
let
  name = "immich";
  port = 2283;
  ip = "192.168.2.50";
in
{
  services.immich.enable = true;
  services.immich.host = ip;
  services.immich.port = port;

  services.immich.mediaLocation = "/mnt/tank/media/photos/immich";

  services.immich.group = "tankusers";

  services.immich.openFirewall = true;

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Immich";
      url = "immich.laufin.xyz";
      icon = "camera";
      inherit port;
      gatusName = name;
    })
  ];
}
