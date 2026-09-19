{
  lib,
  ...
}:
let
  name = "name";
  port = 0000;
in
{
  #services.ntfy-sh.enable = true;

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      inherit name port;
      # Flame app tile — url is the public domain, icon is a Material
      # Design Icons name (see https://pictogrammers.com/library/mdi/).
      url = "${name}.laufin.xyz";
      icon = "cancel";
    })
  ];
}
