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

## Let's modify your ZFS settings to be more permissive for Jellyfin:
1. **Change aclinherit to passthrough**:
``` bash
   sudo zfs set aclinherit=passthrough tank/media
```
This ensures that new files and directories inherit all ACL entries from the parent directory.
1. **Ensure proper group ownership**:
``` bash
   sudo chown -R :tankusers /mnt/tank/media
```
1. **Set proper permissions**:
``` bash
   sudo chmod -R 775 /mnt/tank/media
```
1. **Add posix ACLs to ensure group permissions propagate**:
``` bash
   sudo setfacl -R -m g:tankusers:rwx /mnt/tank/media
   sudo setfacl -R -d -m g:tankusers:rwx /mnt/tank/media
```
