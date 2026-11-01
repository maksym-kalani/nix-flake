{ lib, ... }:
let
  name = "excalidraw";
  port = 3010;
  dataDir = "/var/lib/containers/${name}";
in
{
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Excalidraw";
      url = "excalidraw.laufin.xyz";
      icon = "draw";
      ip = "127.0.0.1";
      inherit port;
      gatusName = name;
      healthPath = "/health";
      healthConditions = [ "[BODY].status == healthy" ];
    })
  ];

  virtualisation.oci-containers.containers.${name} = {
    image = "ghcr.io/frankhommers/mcp-excalidraw-live@sha256:24df361f1eb2c756da96875b480721c6883eb50f11966961f59e52e44c124946";
    ports = [ "127.0.0.1:${toString port}:3000" ];
    volumes = [ "${dataDir}:/data" ];
    environment = {
      BASE_URL = "https://excalidraw.laufin.xyz";
      HOST_HOME_MOUNT = "/data";
      HOST_HOME_PATH = "/data";
      LOG_FILE_PATH = "/tmp/excalidraw.log";
    };
    extraOptions = [
      "--read-only"
      "--tmpfs=/tmp:rw,nosuid,nodev,size=64m,mode=1777"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
  };

  systemd.tmpfiles.rules = [ "d ${dataDir} 0700 1001 1001 -" ];
}
