{ config, pkgs, lib, ... }:

let
  wgPubKey = "VN7PbLuaYTpbEB20O8vkF1fuEWD2bvTsfcHNLs709ks=";    # wireguard pubkey you generated
  wgPrivFile = "/etc/wireguard/server.key";  # private key file on the server
  homeNet = "192.168.2.0/24";         # your actual LAN
  wgNet   = "10.0.0.0/24";            # wireguard network
  extIf = "enp11s0";              # *your* uplink interface name
in {
  networking.wireguard.interfaces.wg0 = {
    # 1) Give the interface an IP on the private wg network
    ips = [ "10.0.0.1/24" ];

    # 2) Listen on UDP port 51820
    listenPort = 51820;

    # 3) Point at your private key
    privateKeyFile = wgPrivFile;

    # 4) Define a peer (your phone)
    peers = [
      {
        # phone’s public key (you’ll import config into the mobile app)
        publicKey = "XSUTfuoPZybBAbPySsFsbT2VK2zeONCLxe/EhmjJUyU=";

        # Tell the server how to send packets back:
        allowedIPs = [ "10.0.0.2/32" ];  
        # This means: “When I send anything for 10.0.0.2 OR 192.168.1.0/24,
        # encrypt and send to the phone.”

        # Keep NAT mappings alive (phone often behind NAT/mobile network)
        persistentKeepalive = 25;
      }
    ];
  };
  
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    # If you also want IPv6:
    #"net.ipv6.conf.all.forwarding" = 1;
  };
  
  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg0" ];
    externalInterface = extIf;
  };

  
  # Manually MASQUERADE wg0→extIf
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 51820 ]; # WireGuard port

    # Forward traffic from wg0 to extIf (LAN/WAN)
    interfaces."wg0".allowedTCPPortRanges = []; # Add if TCP needed
    interfaces."wg0".allowedUDPPortRanges = []; # Add if UDP needed
    # This is a more declarative way to allow forwarding from wg0.
    # For allowing *all* traffic from wg0 to extIf and vice-versa:
    trustedInterfaces = [ "wg0" ]; # Trust wg0 for input TO server
                                  # For forwarding, we need forwardTo associations or explicit rules

    # Explicitly allow forwarding between wg0 and extIf
    # This will create the necessary FORWARD chain rules.
    extraCommands = ''
      iptables -I FORWARD 1 -i wg0 -o ${extIf} -j ACCEPT
      iptables -I FORWARD 2 -i ${extIf} -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    '';
  };
  
  # Add explicit post-up commands to the WireGuard interface configuration
  # This ensures we DON'T add any routes for LAN subnets on the WireGuard interface
  networking.wireguard.interfaces.wg0 = {
    postSetup = ''
      # Remove any erroneous routes for the LAN subnet on wg0 if they exist
      ip route del ${homeNet} dev wg0 || true
    '';
  };

}
