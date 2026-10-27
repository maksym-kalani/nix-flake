{
  ...
}:
let
  wireguardConfig = {
    serverPrivateKeyFile = "/etc/wireguard/server.key";
    serverAddress = "10.0.0.1/24";
    listenPort = 51820;
    networkCIDR = "10.0.0.0/24";
  };

  networkConfig = {
    externalInterface = "enp11s0";
    homeNetworkCIDR = "192.168.2.0/24";
  };

  phoneClient = {
    publicKey = "XSUTfuoPZybBAbPySsFsbT2VK2zeONCLxe/EhmjJUyU=";
    address = "10.0.0.2/32";
    keepAliveSeconds = 25;
  };
  eklesaPhoneClient = {
    publicKey = "2vPVo5il8075Bq/aXLNmEGl/H2UTSNNBc5t8kQl07yU=";
    address = "10.0.0.3/32";
    keepAliveSeconds = 25;
  };
  tabletClient = {
    publicKey = "BFKqnJBlG6ANmzXId3wV/JvooVOoUS5IAocm6k2H8E0=";
    address = "10.0.0.4/32";
    keepAliveSeconds = 25;
  };
in
{
  networking.wireguard.interfaces.wg0 = {
    ips = [ wireguardConfig.serverAddress ];
    listenPort = wireguardConfig.listenPort;
    privateKeyFile = wireguardConfig.serverPrivateKeyFile;

    peers = [
      {
        publicKey = phoneClient.publicKey;
        allowedIPs = [ phoneClient.address ];
        persistentKeepalive = phoneClient.keepAliveSeconds;
      }
      {
        publicKey = eklesaPhoneClient.publicKey;
        allowedIPs = [ eklesaPhoneClient.address ];
        persistentKeepalive = eklesaPhoneClient.keepAliveSeconds;
      }
      {
        publicKey = tabletClient.publicKey;
        allowedIPs = [ tabletClient.address ];
        persistentKeepalive = tabletClient.keepAliveSeconds;
      }
    ];

    postSetup = ''
      # Prevent routing home network traffic through WireGuard
      ip route del ${networkConfig.homeNetworkCIDR} dev wg0 || true
    '';
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg0" ];
    externalInterface = networkConfig.externalInterface;
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ wireguardConfig.listenPort ];

    interfaces."wg0" = {
      allowedTCPPortRanges = [ ];
      allowedUDPPortRanges = [ ];
    };

    trustedInterfaces = [ "wg0" ];

    extraCommands = ''
      iptables -I FORWARD 1 -i wg0 -o ${networkConfig.externalInterface} -j ACCEPT
      iptables -I FORWARD 2 -i ${networkConfig.externalInterface} -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    '';
  };
}
