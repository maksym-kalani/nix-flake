{
  config,
  lib,
  ...
}:
let
  port = 5000;
  name = "kavita";
in
{
  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets.kavita_token_key.path;
    settings.Port = port;
  };

  users.users.kavita.extraGroups = [ "tankusers" ];

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Kavita";
      url = "kavita.laufin.xyz";
      icon = "book-open";
      inherit port;
      gatusName = name;
    })
  ];
}
