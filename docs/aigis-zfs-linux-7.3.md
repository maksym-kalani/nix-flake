# Aigis: Linux 7.3 and stable ZFS 2.4.4

`hosts/aigis/infra/zfs-kernel.nix` selects ordinary `linuxPackages_7_3`,
stable `pkgs.zfs` userspace and the matching patched kernel module through
`boot.zfs.modulePackage`. The lock file is unchanged. The package rejects
anything except stable ZFS **2.4.4** (`zfs_2_4`) on Linux **7.3.x**;
userspace must match the module's source and original userspace derivation.
The experimental flag and `broken = false` apply only to this patched module.

## Sources and validation

The four backports are fetched directly from
[Ubuntu 2.4.4-1ubuntu4](https://git.launchpad.net/ubuntu/+source/zfs-linux/tree/debian/patches?h=import/2.4.4-1ubuntu4)
with SHA-256 hashes in `pkgs/zfs-linux-7.3/default.nix`, rather than copied
into this repository. The adaptation follows the
[nepeat package](https://github.com/nepeat/nepeat/blob/a480e530ec3f781bbf3f34c28c5ed6c04d99bca8/nix/package/zfs-linux-7.3.nix).
Patches must apply with zero fuzz; configure probes and patched source sites
are checked during the module build. The output retains `nix-support/zfs_config.h`
and `compatibility-patches.sha256`.

The existing PR workflow runs formatting, evaluation and `aigis-vm`.
The upstream [focused ZFS VM example](https://github.com/nepeat/nepeat/blob/a480e530ec3f781bbf3f34c28c5ed6c04d99bca8/nix/tests/zfs-linux-7.3.nix)
is linked for reference, not installed as another flake check or CI job.
Full NixOS builds and VM checks belong on the CI runner, not the Hermes container.
A passing evaluation is not a successful build or evidence of the running host.

## Deployment and rollback (separately approved)

Aigis Comin follows `develop` with `switch` every 60 seconds: **merging can
activate this change automatically**. Keep the PR unmerged until deployment
is explicitly approved. This PR does not authorize SSH, activation or reboot.

Before approved deployment, record the current bootable generation, kernel/ZFS
versions, pool status/features and a recoverable backup. Keep that generation
and its boot entry. After approved activation and reboot, check `uname -r`,
`zfs version`, `modinfo zfs`, imported datasets, `zpool status`, service access
and the full boot/import journals for BUG/Oops, I/O and checksum errors.

If boot, import or services regress, boot the recorded previous generation
with its matching kernel and ZFS. Activation alone cannot replace a running
kernel. Prevent automatic redeployment through a separately approved source
rollback. Never run `zpool upgrade` or enable pool features during migration
or rollback; investigate failures before force-import.

## Removing the workaround

Remove the override and local package only when the flake-pinned stable ZFS
supports the selected kernel without experimental/broken overrides and passes
module/userspace builds, disposable storage regression checks and the Aigis
smoke test on the final PR head. A version bump or compilation alone is not
runtime evidence. Moving outside ZFS 2.4.4 / Linux 7.3 deliberately fails closed.
