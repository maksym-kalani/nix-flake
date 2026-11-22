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
    openFirewall = false;
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

  networking.firewall.extraCommands = ''
    # Trusted interfaces must not bypass the Glances source restriction.
    iptables -I nixos-fw-accept 1 ! -i lo -p tcp ! -s 192.168.2.5 --dport ${toString port} -j nixos-fw-refuse
    iptables -A nixos-fw -p tcp -s 192.168.2.5 --dport ${toString port} -j nixos-fw-accept
  '';
}
