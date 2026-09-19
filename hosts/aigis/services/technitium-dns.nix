{
  lib,
  ...
}: let
  appdata = "/var/lib/containers/";
  cfg = {
    name = "dns";

    image = "technitium/dns-server:latest";

    port = {
      internal = 5380;
      external = 5380;
    };

    extraOptions = [];
    volumes = [
      "${appdata}${cfg.name}:/etc/dns"

    ];
    environmentVariables = {
      DNS_SERVER_DOMAIN = "aigis-dns-server";
      DNS_SERVER_ENABLE_BLOCKING = "true";
      DNS_SERVER_BLOCK_LIST_URLS = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_49.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt, https://www.awwwwesome.org/url-blocklist/url-blocklist.txt, https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt, https://blocklistproject.github.io/Lists/adguard/tracking-ags.txt, https://blocklistproject.github.io/Lists/adguard/ads-ags.txt, https://raw.githubusercontent.com/deathbybandaid/piholeparser/master/Subscribable-Lists/CountryCodesLists/Ukraine.txt";
      DNS_SERVER_FORWARDERS = "9.9.9.10, 8.8.8.8, 149.112.112.10";
    };

    autoStart = true;
  };
in {
  imports = [
    (import ../lib/monitored-app.nix { inherit lib; } {
      name = "Technitium DNS";
      url = "dns.laufin.xyz";
      icon = "shield";
      port = cfg.port.external;
      gatusName = cfg.name;
    })
  ];

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}" "53:53/udp" "53:53/tcp"];

    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };

  networking.firewall.allowedTCPPorts = [cfg.port.external 53];
}
