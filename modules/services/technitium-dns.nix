{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.technitium-dns;
  name = "dns";
  port = 5380;
in {
  options.server.services.technitium-dns = {
    enable = lib.mkEnableOption "Technitium DNS server";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "technitium/dns-server:latest";
        ports = [
          "${toString port}:5380"
          "53:53/udp"
          "53:53/tcp"
        ];
        volumes = [
          "${config.server.containerData}/${name}:/etc/dns"
        ];
        environment = {
          DNS_SERVER_DOMAIN = "aigis-dns-server";
          DNS_SERVER_ENABLE_BLOCKING = "true";
          DNS_SERVER_BLOCK_LIST_URLS = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_49.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt, https://www.awwwwesome.org/url-blocklist/url-blocklist.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt, https://blocklistproject.github.io/Lists/adguard/tracking-ags.txt, https://blocklistproject.github.io/Lists/adguard/ads-ags.txt, https://raw.githubusercontent.com/deathbybandaid/piholeparser/master/Subscribable-Lists/CountryCodesLists/Ukraine.txt";
          DNS_SERVER_FORWARDERS = "9.9.9.10, 8.8.8.8, 149.112.112.10";
        };
        autoStart = true;
      };

      networking.firewall.allowedTCPPorts = [ 53 ];
      networking.firewall.allowedUDPPorts = [ 53 ];
    }
  ]);
}
