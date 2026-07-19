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
      basicAuthEnabled = true;
      basicAuthUsername = "maksym";
      basicAuthPasswordFile = config.sops.secrets.tachidesk_password.path;
      extensionRepos = [];

      # Modern auth schema written by Suwayomi 2.x; envsubst substitutes the
      # same secret into authPassword at service start
      authMode = "BASIC_AUTH";
      authUsername = "maksym";
      authPassword = "$TACHIDESK_SERVER_BASIC_AUTH_PASSWORD";

      # Carried over from the previous container's server.conf
      extensionStores = [
        "https://raw.githubusercontent.com/yuzono/manga-repo/repo/index.pb"
        "https://raw.githubusercontent.com/suwayomi/tachiyomi-extension/repo/repo.json"
        "https://raw.githubusercontent.com/yuzono/cursed-manga-repo/repo/index.pb"
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
        "[STATUS] == 401"
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
