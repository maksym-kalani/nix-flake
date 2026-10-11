# LAN-only binary cache (nix-serve). Not exposed via Caddy/Cloudflare.
# Public key (trusted on belial): aigis-cache-1:GzbUfqI4iVQwfw/bl0+zyU1Qak0GF4MnJ9PHSMKUtGs=
{config, ...}: let
  ip = "192.168.2.50";
  port = 5757;
  # bindAddress is not an ACL: Belial sits on another routed subnet, so only allow it explicitly.
  allowedSources = ["192.168.1.107"]; # belial
in {
  # Read by systemd LoadCredential as root, so the default root-only secret is fine.
  sops.secrets.nix_cache_private_key = {};

  services.nix-serve = {
    enable = true;
    bindAddress = ip;
    inherit port;
    openFirewall = false;
    secretKeyFile = config.sops.secrets.nix_cache_private_key.path;
  };

  networking.firewall.extraCommands = builtins.concatStringsSep "\n" (map (src: ''
      iptables -A nixos-fw -p tcp -s ${src} --dport ${toString port} -j nixos-fw-accept
    '')
    allowedSources);

  # "/" is not served by nix-serve; probe the cache metadata endpoint instead.
  services.gatus.settings.endpoints = [
    {
      name = "nix-cache";
      url = "http://${ip}:${toString port}/nix-cache-info";
      interval = "1m";
      conditions = ["[STATUS] == 200"];
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
