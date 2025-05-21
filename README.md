# NixOS Configuration Repository

This repository contains my personal NixOS configurations using the Nix Flakes system. It provides a modular and reproducible way to manage NixOS systems.

## Initial Setup After Fresh NixOS Installation

### Step 1: Configure Your Fresh NixOS Installation

After installing NixOS, you need to enable some essential settings before you can use this flake repository. Add the following to your `/etc/nixos/configuration.nix`:
```nix
services.openssh.enable = true;
nix.settings.experimental-features = [ "nix-command" "flakes" ];
nix.settings.trusted-users = [ "root" "maksym" ];
```

Apply these changes with:

```bash
sudo nixos-rebuild switch
```
### Step 2: Set Up SSH Access from Your Client Machine
On your client machine, generate SSH keys and set up the configuration:
``` bash
cd ~/.ssh
ssh-keygen -f maksym
ssh-copy-id -i ~/.ssh/maksym.pub maksym@192.168.1.55
nano ~/.ssh/config
```
Add this configuration to your SSH config file:
``` 
Host virtual
Hostname 192.168.1.55
User maksym
IdentityFile ~/.ssh/maksym
```
Now you can connect to your NixOS machine with:
``` bash
ssh virtual
```
### Step 3: Clone This Repository
``` bash
git clone https://github.com/yourusername/nixos-config.git
cd nixos-config
```
### Step 4: Validate the Configuration
``` bash
nix flake check --show-trace
```
### Step 5: Apply the Configuration
``` bash
nixos-rebuild switch --flake .#virtual --target-host virtual --use-remote-sudo
```

## Editing Secrets
To edit the encrypted secrets file (), you can use the following command: `secrets.yaml`
``` bash
nix shell nixpkgs#sops -c sops secrets.yaml
```
This command:
1. Creates a temporary shell with SOPS installed from nixpkgs
2. Opens the file in the SOPS editor `secrets.yaml`
3. Automatically encrypts the file when you save and exit

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