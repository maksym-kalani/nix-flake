{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "karakeep";
  port = 3050;
  domain = "laufin.xyz";
  ip = "192.168.2.50";

  # nixpkgs' services.karakeep module still unconditionally injects the
  # meilisearch field `experimental_dumpless_upgrade`, which was renamed to
  # `upgrade_db` in meilisearch 1.51 and is now an unknown-field startup
  # error. Fixed upstream (NixOS/nixpkgs#549487) but not yet in
  # nixos-unstable, so strip the stale key from the generated config
  # ourselves until a flake update picks up that fix.
  # Also drop null-valued keys (e.g. unset ssl_*_path options), which the
  # stock module strips internally before generating TOML but which the TOML
  # generator otherwise fails to serialize.
  meilisearchSettings = lib.filterAttrs (_: v: v != null) (
    builtins.removeAttrs config.services.meilisearch.settings ["experimental_dumpless_upgrade"]
  );
  meilisearchConfigFile = (pkgs.formats.toml {}).generate "config.toml" meilisearchSettings;
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
      upgrade_db = true;
    };
  };

  systemd.services.meilisearch.serviceConfig.ExecStartPre = lib.mkForce [
    "${lib.getExe' pkgs.coreutils "install"} -m 700 '${meilisearchConfigFile}' \"\${RUNTIME_DIRECTORY}/config.toml\""
  ];

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
