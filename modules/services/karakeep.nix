{ config, pkgs, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.karakeep;
  name = "karakeep";
  port = 3050;
in {
  options.server.services.karakeep = {
    enable = lib.mkEnableOption "Karakeep bookmark manager";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.karakeep = {
        enable = true;
        extraEnvironment = {
          PORT = toString port;
          NEXTAUTH_URL = "https://${name}.${config.server.domain}";
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
    }
  ]);
}
