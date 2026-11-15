{ config, ... }:
let
  ip = "192.168.2.50";
  port = 5757;
  # bindAddress is not an ACL: Belial sits on another routed subnet, so only allow it explicitly.
  allowedSources = [ "192.168.1.107" ]; # belial
in
{
  sops.secrets.nix_cache_private_key = { };

  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.sops.secrets.nix_cache_private_key.path ];
    settings = {
      bind = "${ip}:${toString port}";
      priority = 30;
    };
  };
  # The socket may bind before the static address is up.
  systemd.sockets.harmonia.socketConfig.FreeBind = true;

  networking.firewall.extraCommands = builtins.concatStringsSep "\n" (
    map (src: ''
      iptables -A nixos-fw -p tcp -s ${src} --dport ${toString port} -j nixos-fw-accept
    '') allowedSources
  );

  services.gatus.settings.endpoints = [
    {
      name = "Harmonia Cache";
      url = "http://${ip}:${toString port}/nix-cache-info";
      interval = "1m";
      conditions = [ "[STATUS] == 200" ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "nix-cache health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
