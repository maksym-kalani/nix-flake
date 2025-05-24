## Generating Wireguard keys
### 1. On Your NixOS Server: Generate the Server Key-Pair
``` bash
# Become root (or use sudo) so the files land in /etc/wireguard
mkdir -p /etc/wireguard
cd /etc/wireguard

# Ensure only root can read/write these
umask 077

# Generate the private key and save it
wg genkey | tee server.key

# Pipe that into wg pubkey to get the public key
cat server.key | wg pubkey > server.pub

# You now have:
#  - /etc/wireguard/server.key   (keep this secret!)
#  - /etc/wireguard/server.pub   (this is your SERVER_PUBLIC_KEY)
```
You then reference /etc/wireguard/server.key in your NixOS module (privateKeyFile = "/etc/wireguard/server.key"), and expose the contents of /etc/wireguard/server.pub as SERVER_PUBLIC_KEY in your phone’s config.

### 2. On Your Phone (or Any Client): Generate the Client Key-Pair

You can either:
1. Use the WireGuard app
    - On iOS/Android, open the app, tap “Add → Generate keypair.”
    - It will show you the public and private key in the new peer’s config screen.
2. Or generate locally on another machine (Linux/Mac):

### On any Linux/Mac with wg installed:
``` bash
umask 077
wg genkey | tee phone.key | wg pubkey > phone.pub

# phone.key  = your PHONE_PRIVATE_KEY
# phone.pub  = your PHONE_PUBLIC_KEY
```
Then copy phone.key into your WireGuard app’s “PrivateKey” field and paste phone.pub into the server’s peers.publicKey in your NixOS config.

### 3. Wire Them Together

Server config (in NixOS):
``` nix
peers = [
    {
        publicKey           = builtins.readFile /etc/wireguard/phone.pub;
        allowedIPs          = [ "10.0.0.2/32" "192.168.1.0/24" ];
        persistentKeepalive = 25;
    }
];
```
Client config (in your phone’s WireGuard app):
``` ini
[Interface]
Address     = 10.0.0.2/32
PrivateKey  = <contents of phone.key>

[Peer]
PublicKey   = <contents of server.pub>
Endpoint    = your.ddns.name:51820
AllowedIPs  = 0.0.0.0/0, ::/0      # or 10.0.0.0/24,192.168.1.0/24
PersistentKeepalive = 25
```
Once both sides know each other’s public keys, the tunnel will come up and you’ll be routed into your home LAN just as if you were on Wi-Fi.
