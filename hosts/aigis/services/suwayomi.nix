{
  config,
  lib,
  ...
}:
let
  name = "suwayomi";
  port = 4568;
in
{
  # Preserve the served WebUI copy, including lazily loaded JavaScript modules.
  systemd.tmpfiles.rules = [
    "x /tmp/Tachidesk - - - - -"
  ];

  services.suwayomi-server = {
    enable = true;
    openFirewall = true;
    # data migrated from /var/lib/containers/tachidesk into the default dataDir

    settings.server = {
      ip = "0.0.0.0";
      inherit port;

      downloadAsCbz = true;
      extensionRepos = [ ];

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

  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Suwayomi";
      url = "manga.laufin.xyz";
      icon = "thought-bubble-outline";
      description = "Manga reader app";
      inherit port;
      gatusName = name;
    })
  ];
}
