{
  pkgs,
  lib,
  ...
}:
let
  name = "vikunja";
  port = 1337;
  domain = "laufin.xyz";
in
{
  services.vikunja = {
    package = pkgs.vikunja;
    enable = true;
    port = port;
    frontendHostname = "todo.${domain}";
    frontendScheme = "https";
  };

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "TODO";
      url = "todo.laufin.xyz";
      icon = "checkbox-marked-outline";
      inherit port;
      gatusName = name;
    })
  ];
}
