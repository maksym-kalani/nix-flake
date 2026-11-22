{ config, lib, ... }:
let
  port = config.services.glances.port;
in
{
  imports = [
    ((import ../lib/monitored-app.nix { inherit lib; }) {
      name = "Glances";
      enableFlame = false;
      ip = "127.0.0.1";
      inherit port;
      healthPath = "/api/4/status";
    })
  ];

  services.glances = {
    enable = true;
    openFirewall = true;
    extraArgs = [
      "--webserver"
      "--disable-webui"
      "--bind"
      "0.0.0.0"
      "--disable-plugin"
      "all"
      "--enable-plugin"
      "sensors,system"
      "--disable-check-update"
      "--disable-config-exec"
    ];
  };
}
