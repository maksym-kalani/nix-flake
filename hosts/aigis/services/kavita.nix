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
  sops.secrets.kavita_token_key = { };

  services.kavita = {
    enable = true;
    credentials.token_key = config.sops.secrets.kavita_token_key.path;
    settings.TokenKey = "@token_key@";
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
      healthPath = "/api/health";
      gatusName = name;
    })
  ];
}
