{ config, pkgs, lib, ... }:
let
  # WireGuard Network Configuration
  wireguardConfig = {
    serverPrivateKeyFile = "/etc/wireguard/server.key";
    serverAddress = "10.0.0.1/24";
    listenPort = 51820;
    networkCIDR = "10.0.0.0/24";
  };

  # Network Interface Configuration
  networkConfig = {
    externalInterface = "enp11s0";     # Your uplink interface name
    homeNetworkCIDR = "192.168.2.0/24"; # Your actual LAN
  };

  # Client Configuration
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
in {
  # WireGuard Interface Configuration
  networking.wireguard.interfaces.wg0 = {
    # Basic WireGuard configuration
    ips = [ wireguardConfig.serverAddress ];
    listenPort = wireguardConfig.listenPort;
    privateKeyFile = wireguardConfig.serverPrivateKeyFile;
    
    # Client peer definitions
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
    ];
    
    # Post-setup commands to ensure proper routing
    postSetup = ''
      # Prevent routing home network traffic through WireGuard
      ip route del ${networkConfig.homeNetworkCIDR} dev wg0 || true
    '';
  };
  
  # Kernel network configuration
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    # Uncomment for IPv6 support:
    # "net.ipv6.conf.all.forwarding" = 1;
  };
  
  # NAT configuration
  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg0" ];
    externalInterface = networkConfig.externalInterface;
  };
  
  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ wireguardConfig.listenPort ];
    
    # Interface-specific rules
    interfaces."wg0" = {
      allowedTCPPortRanges = []; # Add specific ranges if needed
      allowedUDPPortRanges = []; # Add specific ranges if needed
    };
    
    # Trust WireGuard interface for input TO server
    trustedInterfaces = [ "wg0" ];
    
    # Explicit forwarding rules between WireGuard and external interface
    extraCommands = ''
      iptables -I FORWARD 1 -i wg0 -o ${networkConfig.externalInterface} -j ACCEPT
      iptables -I FORWARD 2 -i ${networkConfig.externalInterface} -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    '';
  };
}