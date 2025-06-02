# file: restart-containers.nix
{ lib, pkgs, ... }:

{
  systemd.timers.restart-containers = {
    timerConfig = {
      Unit = "restart-containers.service";
      OnCalendar = "Tue 04:00";
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.restart-containers = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "restart-podman-containers" ''
        # List all running container IDs and restart each one
        ${pkgs.podman}/bin/podman ps -q | xargs -r ${pkgs.podman}/bin/podman restart
      '');
    };
  };
}
