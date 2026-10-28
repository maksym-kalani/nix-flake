{
  config,
  pkgs,
  lib,
  ...
}:
let
  name = "karakeep";
  port = 3050;
  domain = "laufin.xyz";
in
{
  sops.secrets.openai_api_key = { };

  services.karakeep = {
    enable = true;
    extraEnvironment = {
      PORT = "${toString port}";
      NEXTAUTH_URL = "https://${name}.${domain}";
      DISABLE_NEW_RELEASE_CHECK = "true";
      OCR_LANGS = "eng,ukr";
    };
    environmentFile = config.sops.secrets.openai_api_key.path;
  };

  # upstream unit neither waits for its backends nor restarts, so a slow boot leaves it dead
  systemd.services.karakeep-workers = {
    after = [
      "karakeep-browser.service"
      "meilisearch.service"
    ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  services.meilisearch = {
    enable = true;
    package = pkgs.meilisearch;
    settings = {
      upgrade_db = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Karakeep";
      url = "karakeep.laufin.xyz";
      icon = "bookmark-check-outline";
      inherit port;
      healthPath = "/api/health";
      healthConditions = [ "[BODY].status == ok" ];
      gatusName = name;
    })
  ];
}
