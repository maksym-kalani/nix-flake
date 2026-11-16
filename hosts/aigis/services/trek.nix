{ lib, ... }:
let
  name = "trek";
  port = 3011;
  dataDir = "/var/lib/containers/${name}";
in
{
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "TREK";
      url = "trek.laufin.xyz";
      icon = "map-marker-path";
      ip = "127.0.0.1";
      inherit port;
      gatusName = name;
      healthPath = "/api/health";
    })
  ];

  virtualisation.oci-containers.containers.${name} = {
    image = "docker.io/mauriceboe/trek@sha256:991ff5aa53244b25d5a8ea40361dc286cfc8211638044eabe12b9926729db5cc";
    user = "1000:1000";
    ports = [ "127.0.0.1:${toString port}:3000" ];
    volumes = [
      "${dataDir}/data:/app/data"
      "${dataDir}/uploads:/app/uploads"
    ];
    environment = {
      TZ = "Europe/Kyiv";
      DEFAULT_LANGUAGE = "uk";
      APP_URL = "https://trek.laufin.xyz";
      ALLOWED_ORIGINS = "https://trek.laufin.xyz";
    };
    extraOptions = [
      "--read-only"
      "--tmpfs=/tmp:rw,noexec,nosuid,nodev,size=128m,mode=1777"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 root root -"
    "d ${dataDir}/data 0700 1000 1000 -"
    "d ${dataDir}/uploads 0700 1000 1000 -"
  ];
}
