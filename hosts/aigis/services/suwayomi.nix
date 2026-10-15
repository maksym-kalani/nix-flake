{
  config,
  lib,
  ...
}: let
  name = "suwayomi";
  port = 4568;
  # WebInterfaceManager serves a working copy from /tmp/Tachidesk/webUI-serve.
  # Age-based cleanup must not remove its lazily loaded JavaScript modules.
  webuiTmpfilesRules = [
    "x /tmp/Tachidesk - - - - -"
  ];
in {
  systemd.tmpfiles.rules = webuiTmpfilesRules;

  # On deployment, also rebuild the served copy using Suwayomi's startup logic.
  # Tie the restart to this policy only, not to unrelated tmpfiles changes.
  systemd.services.suwayomi-server.restartTriggers = [
    (builtins.toFile "suwayomi-webui-tmpfiles.conf" (lib.concatLines webuiTmpfilesRules))
  ];

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
