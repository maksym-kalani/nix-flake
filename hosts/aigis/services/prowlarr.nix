{
  lib,
  ...
}:
let
  name = "prowlarr";
  port = 9696;
in
{
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Prowlarr";
      url = "prowlarr.laufin.xyz";
      icon = "alpha-p-box-outline";
      inherit port;
      healthPath = "/ping";
      healthConditions = [ "[BODY].status == OK" ];
      gatusName = name;
    })
  ];
}
