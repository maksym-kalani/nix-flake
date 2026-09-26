{ config, lib, ... }:
let
  port = 8882;
in
{
  sops.secrets.searxng_secret_key.owner = "searx";

  sops.templates."searxng-env" = {
    owner = "searx";
    content = ''
      SEARXNG_SECRET_KEY=${config.sops.placeholder.searxng_secret_key}
    '';
  };

  services.searx = {
    enable = true;
    environmentFile = config.sops.templates."searxng-env".path;
    settings = {
      use_default_settings = true;

      search = {
        autocomplete = "google";
        autocomplete_min = 3;
        favicon_resolver = "google";
        formats = [
          "html"
          "json"
        ];
        suspended_times = {
          SearxEngineAccessDenied = 86400;
          SearxEngineCaptcha = 86400;
          SearxEngineTooManyRequests = 3600;
          cf_SearxEngineCaptcha = 1296000;
          cf_SearxEngineAccessDenied = 86400;
          recaptcha_SearxEngineCaptcha = 604800;
        };
      };

      server = {
        port = port;
        bind_address = "0.0.0.0";
        base_url = "/";
        secret_key = "$SEARXNG_SECRET_KEY";
      };

      ui.infinite_scroll = true;

      plugins."searx.plugins.tracker_url_remover.SXNGPlugin".active = false;

      engines = [
        {
          name = "cloudflareai";
          disabled = true;
        }
        {
          name = "duckduckgo images";
          disabled = true;
        }
        {
          name = "duckduckgo news";
          disabled = true;
        }
        {
          name = "duckduckgo videos";
          disabled = true;
        }
        {
          name = "il post";
          disabled = false;
        }
        {
          name = "libretranslate";
          disabled = true;
        }
        {
          name = "public domain image archive";
          disabled = false;
        }
        {
          name = "qwant images";
          disabled = false;
        }
        {
          name = "qwant news";
          disabled = false;
        }
        {
          name = "qwant videos";
          disabled = false;
        }
        {
          name = "semantic scholar";
          disabled = true;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "SearxNG";
      url = "search.laufin.xyz";
      icon = "search-web";
      inherit port;
      gatusName = "search";
    })
  ];
}
