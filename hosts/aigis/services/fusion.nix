{
  lib,
  ...
}: let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "fusion";

    image = "ghcr.io/0x2e/fusion@sha256:4fa7eead46976f2090cfbb7e60f29946eccf0a5979c1fc168d7a9d89648a6a9b"; # pinned to what aigis ran on 2026-10-27

    port = {
      internal = 8080;
      external = 8085;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}:/data"

    ];
    environmentVariables = {
      FUSION_ALLOW_EMPTY_PASSWORD = "true";
    };

    autoStart = true;
  };
in {
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Fusion RSS";
      url = "rss.laufin.xyz";
      icon = "rss-box";
      port = cfg.port.external;
      gatusName = cfg.name;
    })
  ];

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };

  networking.firewall.allowedTCPPorts = [cfg.port.external];

  systemd.tmpfiles.rules = ["d ${appdata}${cfg.name} :0755 :root :root -"];
}
