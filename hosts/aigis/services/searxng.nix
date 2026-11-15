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
    faviconsSettings.favicons = {
      cfg_schema = 1;
      cache = {
        db_url = "/var/cache/searx/faviconcache.db";
        LIMIT_TOTAL_BYTES = 134217728;
        MAINTENANCE_MODE = "auto";
        MAINTENANCE_PERIOD = 3600;
      };
    };
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

      # SearXNG replaces the complete upstream plugin registration map.
      plugins = {
        "searx.plugins.calculator.SXNGPlugin".active = true;
        "searx.plugins.infinite_scroll.SXNGPlugin".active = true;
        "searx.plugins.hash_plugin.SXNGPlugin".active = true;
        "searx.plugins.self_info.SXNGPlugin".active = true;
        "searx.plugins.unit_converter.SXNGPlugin".active = true;
        "searx.plugins.ahmia_filter.SXNGPlugin".active = true;
        "searx.plugins.hostnames.SXNGPlugin".active = true;
        "searx.plugins.time_zone.SXNGPlugin".active = true;
        "searx.plugins.oa_doi_rewrite.SXNGPlugin".active = false;
        "searx.plugins.tor_check.SXNGPlugin".active = false;
        "searx.plugins.tracker_url_remover.SXNGPlugin".active = true;
      };

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
      healthPath = "/healthz";
      healthConditions = [ "[BODY] == OK" ];
      gatusName = "search";
    })
  ];
}
