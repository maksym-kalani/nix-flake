{
  lib,
  ...
}:
let
  appdata = "/srv/kiwix";
  port = 8012;
  name = "kiwix";
in
{
  services.kiwix-serve = {
    enable = true;
    port = port;
    library = {
      "wikipedia_en_all_maxi_2025-08" = "${appdata}/wikipedia_en_all_maxi_2025-08.zim";
      "wikipedia_uk_all_maxi_2025-09" = "${appdata}/wikipedia_uk_all_maxi_2025-09.zim";
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Wikipedia";
      url = "wikipedia.laufin.xyz";
      icon = "wikipedia";
      inherit port;
      gatusName = name;
    })
  ];
}
