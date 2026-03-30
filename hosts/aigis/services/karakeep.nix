{
  config,
  pkgs,
  ...
}: let
  name = "karakeep";
  port = 3050;
  domain = "laufin.xyz";
  ip = "192.168.2.50";
in {
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

  services.meilisearch = {
    enable = true;
    package = pkgs.meilisearch;
    settings = {
      experimental_dumpless_upgrade = true;
    };
  };

  networking.firewall.allowedTCPPorts = [port];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "http://${ip}:${toString port}";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
