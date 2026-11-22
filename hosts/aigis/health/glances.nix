{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = config.services.glances.port;
  glancesConfig = (pkgs.formats.ini { }).generate "glances.conf" {
    sensors.alias = "i915 0_temperature_core:GPU temperature,i915 0_fan_speed:GPU fan";
  };
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
      "--config"
      "${glancesConfig}"
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
