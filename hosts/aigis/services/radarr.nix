{
  lib,
  ...
}:
let
  name = "radarr";
  port = 7878;
in
{
  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.radarr.extraGroups = [ "tankusers" ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Radarr";
      url = "radarr.laufin.xyz";
      icon = "alpha-r-box-outline";
      inherit port;
      healthPath = "/ping";
      healthConditions = [ "[BODY].status == OK" ];
      gatusName = name;
    })
  ];
}
