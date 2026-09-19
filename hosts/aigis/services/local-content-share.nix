{
  lib,
  ...
}:
let
  port = 8087;
  name = "local-content-share";
in
{
  services.local-content-share = {
    enable = true;
    port = port;
  };

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Local Content Share";
      url = "share.laufin.xyz";
      icon = "share";
      inherit port;
      gatusName = name;
    })
  ];
}
