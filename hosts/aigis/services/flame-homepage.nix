{
  config,
  ...
}:
let
  ip = "192.168.2.50";
  name = "home";
  port = 3311;
in
{
  services.flame = {
    enable = true;
    inherit port;
    openFirewall = true;
    passwordFile = config.sops.secrets.flame_password.path;

    apps = [
      {
        name = "Home Assistant";
        url = "hass.laufin.online";
        icon = "home-assistant";
        isPinned = true;
      }
    ];

    categories = [
      {
        name = "IoT";
        isPinned = true;
        bookmarks = [
          {
            name = "AWTRIX";
            url = "192.168.3.38";
          }
          {
            name = "WLED Stick";
            url = "192.168.3.39";
          }
          {
            name = "WLED Wall";
            url = "http://192.168.3.31/";
          }
        ];
      }
      {
        name = "Management";
        isPinned = true;
        bookmarks = [
          {
            name = "JetKVM";
            url = "192.168.2.39";
            icon = "keyboard-settings-outline";
          }
          {
            name = "Portainer at BananaPi";
            url = "https://192.168.5.5:9443";
            icon = "docker";
          }
          {
            name = "Portainer at Morgana";
            url = "portainer.laufin.xyz";
            icon = "docker";
          }
          {
            name = "Proxmox at Morgana";
            url = "192.168.2.20:8006";
            icon = "server";
          }
        ];
      }
      {
        name = "Morgana";
        isPinned = true;
        bookmarks = [
          {
            name = "CUPS Printer";
            url = "192.168.2.204:631";
            icon = "printer";
          }
          {
            name = "Foundry";
            url = "https://foundry.laufin.online/";
            icon = "dice-d20-outline";
          }
          {
            name = "Kavita Online";
            url = "books.laufin.online";
            icon = "book-open";
          }
          {
            name = "Matrix";
            url = "https://matrix.laufin.online/_matrix/static/";
            icon = "chat";
          }
          {
            name = "Otter Wiki";
            url = "wiki.laufin.online";
            icon = "wikipedia";
          }
          {
            name = "Technitium DNS 2";
            url = "dns2.laufin.xyz";
            icon = "shield";
          }
        ];
      }
      {
        name = "Network";
        isPinned = true;
        bookmarks = [
          {
            name = "Router";
            url = "192.168.1.1";
            icon = "router-network";
          }
          {
            name = "Switch";
            url = "http://192.168.1.3";
            icon = "switch";
          }
        ];
      }
    ];

    settings = {
      weatherApiKeyFile = config.sops.secrets.flame_weather_api_key.path;
      lat = 50.45;
      long = 30.42;
      isCelsius = true;
      customTitle = "Laufin's Homelab";
      pinAppsByDefault = true;
      pinCategoriesByDefault = true;
      hideHeader = false;
      useOrdering = "name";
      appsSameTab = false;
      bookmarksSameTab = true;
      searchSameTab = true;
      hideApps = false;
      hideCategories = false;
      hideSearch = false;
      defaultSearchProvider = "s";
      secondarySearchProvider = "d";
      dockerApps = false;
      dockerHost = "192.168.2.201";
      kubernetesApps = false;
      unpinStoppedApps = true;
      useAmericanDate = false;
      disableAutofocus = false;
      greetingsSchema = "Good evening!;Good afternoon!;Good morning!;Good night!";
      daySchema = "Sunday;Monday;Tuesday;Wednesday;Thursday;Friday;Saturday";
      monthSchema = "January;February;March;April;May;June;July;August;September;October;November;December";
      showTime = false;
      defaultTheme = "#dfd9d6;#98c379;#282c34";
      isKilometer = true;
      weatherData = "cloud";
      hideDate = false;
      pinBookmarksByDefault = true;
      hideBookmarks = false;
      hideEmptyCategories = true;
    };
  };

  services.gatus.settings.endpoints = [
    {
      inherit name;
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
