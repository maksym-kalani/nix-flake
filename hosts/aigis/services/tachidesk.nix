{
  config,
  ...
}: let
  ip = "192.168.2.50";
  name = "tachidesk";
  port = 4568;
in {
  sops.secrets.tachidesk_password = {
    key = "tachidesk_password";
    owner = config.services.suwayomi-server.user;
  };

  services.suwayomi-server = {
    enable = true;
    openFirewall = true;
    # dataDir left at default /var/lib/suwayomi-server;
    # data migrated from /var/lib/containers/tachidesk
    # (see docs/tachidesk-suwayomi-migration.md)

    settings.server = {
      ip = "0.0.0.0";
      inherit port;

      downloadAsCbz = true;
      extensionRepos = [];

      # Carried over from the previous container's server.conf
      extensionStores = [
        "https://github.com/keiyoushi/extensions/raw/repo/index.pb"
        "https://github.com/yuzono/cursed-manga-repo/raw/repo/index.pb"
      ];

      autoDownloadNewChapters = true;
      excludeEntryWithUnreadChapters = false;
      maxSourcesInParallel = 3;
      excludeUnreadChapters = false;
      excludeNotStarted = false;
      excludeCompleted = false;
      updateMangas = true;
      opdsItemsPerPage = 50;

      flareSolverrEnabled = true;
      flareSolverrUrl = "http://127.0.0.1:8191";
    };
  };

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
