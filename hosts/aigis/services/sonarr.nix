{
  lib,
  ...
}:
let
  name = "sonarr";
  port = 8989;
in
{
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.sonarr.extraGroups = [ "tankusers" ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Sonarr";
      url = "sonarr.laufin.xyz";
      icon = "alpha-s-box-outline";
      inherit port;
      gatusName = name;
    })
  ];
}
