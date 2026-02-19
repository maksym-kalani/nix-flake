{
  config,
  pkgs,
  ...
}: {
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/namecheap@v0.0.0-20250228023406-ef9fadb67785"];
      hash = "sha256-4yM9mgG084UaUzVNSxAJiCfvF+9JLW92rq7m3qQOIJw=";
    };
    configFile = "/var/lib/caddy/Caddyfile";
    group = "tankusers";
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
