{ config, ... }:
let
  ip = "192.168.2.50";
  port = 8882;
in
{
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

  services.gatus.settings.endpoints = [
    {
      name = "search";
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
          description = "search health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
