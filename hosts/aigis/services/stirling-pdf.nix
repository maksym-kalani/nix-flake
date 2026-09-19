{
  pkgs,
  lib,
  ...
}:
let
  port = 7080;
  name = "stirling-pdf";
in
{
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = port;
      SECURITY_ENABLELOGIN = false;
      SYSTEM_DEFAULTLOCALE = "en-US";
      SYSTEM_GOOGLEVISIBILITY = true;
      SYSTEM_MAXFILESIZE = "1000";
      UI_APPNAMENAVBAR = "Stirling-PDF-Ultra-lite Latest";
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Stirling PDF";
      url = "stirling-pdf.laufin.xyz";
      icon = "file-pdf-box";
      inherit port;
      gatusName = name;
    })
  ];
}
