{
  config,
  pkgs,
  ...
}:
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785" ];
      hash = "sha256-oizijdZV+1kkR9BPrVmo/uzV4WwMlb5r7uSN1hAANtk=";
    };
    configFile = "/var/lib/caddy/Caddyfile";
    group = "tankusers";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
