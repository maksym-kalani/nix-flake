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

## ZFS configuration manual steps

Wipe existing partition tables: If the drives have been used before, you may want to clear any partition table or ZFS label. You can use gdisk or wipefs. For example:
``` bash
sudo wipefs -a /dev/sda
sudo wipefs -a /dev/sdb
```
This ensures we start with a clean disk. (Be careful to target the correct devices – this will destroy data on those drives.)

Create the mirrored zpool: Use zpool create with appropriate options. We’ll create a pool named tank consisting of a mirror of the two drives. We will also set some pool/dataset properties for optimal defaults. For instance:
```bash
sudo zpool create -o ashift=12 \
  -O compression=lz4 -O atime=off -O xattr=sa -O acltype=posixacl \
  -m /mnt/tank \
  tank mirror \
  /dev/disk/by-id/<disk1-id> /dev/disk/by-id/<disk2-id>
```
Let’s break down this command:

- ashift=12 ensures the pool uses 4KiB sectors alignment. This is important for modern 4Kn drives (and generally safe to use for most drives) to avoid performance penalties.
- -O compression=lz4 enables lz4 compression by default on all datasets in the pool. lz4 is lightweight and will speed up I/O for compressible data (and virtually no downside for incompressible data, as it early-aborts).
- -O atime=off disables updating file access times. This is recommended for performance on spinning disks – it prevents extra writes every time a file is read, which is usually unnecessary for a data pool.
- -O xattr=sa -O acltype=posixacl store extended attributes in the file system (sa) and enable POSIX ACL support. These settings are good for compatibility with Samba and Linux permissions. They allow efficient storage of ACLs and xattrs (for example, Samba can store Windows ACLs as extended attributes if needed).
- -m /mnt/tank sets the mount point for the pool’s root dataset. We want the pool to mount at /mnt/tank. By specifying this at create time, the pool’s root dataset (tank) will have mountpoint=/mnt/tank. ZFS will automatically create the mount directory if needed and mount the filesystem. (If the directory /mnt/tank does not exist, ZFS will create it
- tank mirror /dev/disk/by-id/... disk2 defines the pool name and the vdev layout. We choose the name tank and specify a mirror vdev of the two disks. Ensure you replace <disk1-id> and <disk2-id> with the actual by-id identifiers of /dev/sda and /dev/sdb identified earlier.
After running this command, the pool should be created and mounted. You can verify with:
```bash
sudo zpool status tank    # shows the pool status and mirror vdev
sudo zfs list tank        # shows the root dataset and mountpoint
```
You should see tank online with both sda and sdb under a mirror, and tank mounted at /mnt/tank. From now on, the ZFS pool will manage mounting this filesystem.
Create ZFS Datasets for Data:
With the pool in place, we’ll create the desired datasets within tank. Each dataset will be used for a specific purpose and can have its own properties (like compression, record size, share settings, etc). Using separate datasets (instead of just directories) is beneficial because we can tune them individually and manage quotas/snapshots per dataset if needed.
```bash
sudo zfs create tank/container-data
sudo zfs create tank/downloads
sudo zfs create tank/media
sudo zfs create tank/users
sudo zfs set recordsize=16K tank/downloads
sudo zfs set recordsize=1M tank/media
```
Permissions Check (One-Time)
Change the group ownership of the dataset directories to tankusers, and possibly the owner to one of the users (or leave as root but group-writable – however, having an actual user as owner might be cleaner). For example:
```bash
sudo chown -R maksym:tankusers /mnt/tank/container-data
sudo chown -R maksym:tankusers /mnt/tank/downloads
sudo chown -R maksym:tankusers /mnt/tank/media
sudo chown -R maksym:tankusers /mnt/tank/users
sudo chmod g+s /mnt/tank/container-data \
              /mnt/tank/downloads \
              /mnt/tank/media \
              /mnt/tank/users
```
# Expanding the ZFS Pool in the Future (Manual)
Install the new drives in the system and identify their /dev/disk/by-id paths (just like we did for the first two drives). Assume we find them as <disk3-id> and <disk4-id>.

Attach as a new mirror vdev: Run the command:
```bash
sudo zpool add tank mirror /dev/disk/by-id/<disk3-id> /dev/disk/by-id/<disk4-id>
```
This tells ZFS to add a new mirror pair to the pool tank. After this, zpool status will show tank consisting of two mirror vdevs (each mirror has two legs). The pool’s total storage capacity will increase (roughly doubling, minus ZFS overhead). Data will not automatically rebalance onto the new drives; new writes will start using them (and you can manually rebalance if needed by scrubbing). The pool remains accessible during this operation.

No config change needed: Because the pool name is the same (tank), and we already have boot.zfs.extraPools = [ "tank" ] in place, NixOS will import the pool with all vdevs on boot as usual. There’s no need to add anything to configuration.nix for the new drives. (It might be wise to update any documentation you keep about which drives are in the pool, and you may want to label the drives physically).

Verify: After adding, run zpool status to ensure the new mirror is added and resilvering is not needed (since it was adding empty drives, there’s nothing to resilver except if ZFS does a quick parity check). The status should show all vdevs ONLINE. Also check zpool list tank to see the new size, and possibly do a sudo zpool scrub tank for good measure, to ensure everything is consistent.