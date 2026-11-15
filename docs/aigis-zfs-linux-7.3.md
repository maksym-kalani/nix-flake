# Aigis: Linux 7.3 and stable ZFS 2.4.4

`hosts/aigis/infra/zfs-kernel.nix` selects the ordinary NixOS
`linuxPackages_7_3`, stable `pkgs.zfs` userspace and the matching patched kernel
module through `boot.zfs.modulePackage`. The lock file is unchanged.
The package rejects anything except stable `zfs_2_4` version **2.4.4** on
Linux **7.3.x**. Userspace must match the module's original userspace derivation
and source, not merely its displayed version. No global `allowBroken` is used.

## Backport provenance

The four files in `pkgs/zfs-linux-7.3/` were compared byte-for-byte with
[Ubuntu 2.4.4-1ubuntu4](https://git.launchpad.net/ubuntu/+source/zfs-linux/tree/debian/patches?h=import/2.4.4-1ubuntu4)
and the [nepeat implementation](https://github.com/nepeat/nepeat/blob/a480e530ec3f781bbf3f34c28c5ed6c04d99bca8/nix/package/zfs-linux-7.3.nix).
They are committed locally so evaluation/builds do not depend on a moving Ubuntu
branch. Preserve their original whitespace, headers and human attribution.

| File | SHA-256 |
| --- | --- |
| `linux-7.3-iops-create-no-flag.patch` | `619c9887e74e374c63e36336494e75db5fc8d155febd94e86f5448ed26e7f71d` |
| `linux-7.3-bvec-iter-bi-offset.patch` | `e6c15c6ce6bc32fd6a2de3ad6f4af4b75f9dd38cb2a1d8b9a56e6dd32d61d8f6` |
| `linux-cpu-feature-enabled.patch` | `a40843fe2e74011af21e408026dd50b52ffa6a9e64766a36d2cac1123198c529` |
| `linux-7.3-kthread-init-fs.patch` | `d8ee87f08176c45b7dcc253db7345cfeb1db481b07db164c5ba0116b729043ba` |

The inode backport retains `HAVE_IOPS_CREATE_IDMAP` on ZFS 2.4.4. The kthread
backport uses init's filesystem, which follows the initrd → stage 2 transition;
capturing the initramfs root at module load would not be equivalent. The module
build checks the selected configure probes and patched source sites and retains
`nix-support/zfs_config.h` and `compatibility-patches.sha256` in its output.
Upstream META still says Linux 7.2: the experimental flag and `broken = false`
apply only to this package after its version guards and four patches.

## Runner-only acceptance

The automatic PR workflow builds every stable userspace output, the patched
module, the evaluation contract and `checks.x86_64-linux.zfs-linux-7-3`.
The existing `aigis-vm` job also exercises the changed Aigis configuration.
Do not run full NixOS builds or either VM check in the Hermes container.

The ZFS VM imports the same kernel policy as production, explicitly loads ZFS
in initrd, proves it was loaded before switch_root, and uses a disposable disk.
It tests data checksums, inode operations, snapshot rollback, send/receive,
encryption key unload/load, scrub, export/import and a second import after a
full VM shutdown/start. Both boot logs are checked for kernel BUG/Oops.
The contract rejects future ZFS versions, development ZFS and other kernel
series while leaving the original unpatched module marked broken.

A passing evaluation is not a successful build, and neither is proof of the
state of the running Aigis host. Use the actual final-head Actions results.

## Deployment and rollback (separately approved)

No activation, SSH, real-pool operation or host reboot is part of this PR.
Before an approved deployment, record the current bootable NixOS generation,
kernel/ZFS versions, `zpool status`, pool feature flags and a recent recoverable
backup. Keep that generation and its boot entry; do not garbage-collect it.
The evaluated Aigis Comin configuration follows `develop` with operation `switch`
and a 60-second poll interval. **Merging this PR can therefore activate it
automatically.** Keep it unmerged until deployment is explicitly approved;
creating/pushing the feature branch is not deployment approval.

After separately approved activation and reboot, verify `uname -r`, `zfs version`,
`modinfo zfs`, the loaded module version, imported pools/mounts and `zpool status`.
Review the full current boot's kernel and ZFS import journals for BUG/Oops,
I/O/checksum errors, failed imports and filesystem lookup failures. Validate
service access to existing datasets without modifying pool features.

If boot/import or service access regresses, select the recorded previous
NixOS generation in the bootloader and boot its known-good kernel and matching
ZFS userspace/module. If still running, an approved rollback to that exact
previous generation can prepare the next boot; a running kernel is not replaced
by activation alone. Prevent automatic redeployment of the bad revision through
a separately approved source rollback/promotion change. Never run `zpool upgrade`
or enable new pool features as part of the kernel migration or rollback: older
ZFS may otherwise be unable to import the pool. Investigate before force-import;
`forceImportRoot = false` is preserved.

## Removing the workaround

Remove only when the flake-pinned **stable** ZFS package natively supports the
selected ordinary kernel and the unpatched module evaluates without a broken
or experimental override. Replace the module override with native selection,
remove the four local patches and package, and adjust the contract accordingly.
Retain and pass the same disposable VM coverage, all required module/userspace
outputs and Aigis smoke test on the exact final PR head. A version bump alone,
a development snapshot or a successful compilation without runtime coverage is
not sufficient. A move outside Linux 7.3 or away from ZFS 2.4.4 deliberately
fails closed until that removal or a separately reviewed compatibility change.
