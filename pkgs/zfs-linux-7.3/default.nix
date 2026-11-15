{
  lib,
  fetchurl,
  zfs,
}:
let
  patches =
    map
      (
        patch:
        fetchurl {
          inherit (patch) name hash;
          url = "https://git.launchpad.net/ubuntu/+source/zfs-linux/plain/debian/patches/${patch.name}?h=import/2.4.4-1ubuntu4";
        }
      )
      [
        {
          name = "linux-7.3-iops-create-no-flag.patch";
          hash = "sha256-YZyYh+dON0xj42M2SU5121/I0VX+vZTob1RI7Sbn9x0=";
        }
        {
          name = "linux-7.3-bvec-iter-bi-offset.patch";
          hash = "sha256-5sFcbOa8Mv1qLeOtb0r0t1+d04yyodi5pW5t0y1h2PY=";
        }
        {
          name = "linux-cpu-feature-enabled.patch";
          hash = "sha256-pAhD/i50ARryHkCAJt1QtS/6ap5kdmo20srBEjGYxSk=";
        }
        {
          name = "linux-7.3-kthread-init-fs.patch";
          hash = "sha256-2O6H8IF2xFt9zCU9tzRc/rHbSBsH2xZMW6ARa3KQQ7o=";
        }
      ];
in
assert lib.assertMsg (
  zfs.version == "2.4.4" && zfs.kernelModuleAttribute == "zfs_2_4"
) "The Linux 7.3 backports require stable ZFS 2.4.4 (zfs_2_4).";
assert lib.assertMsg (
  zfs.kernel != null && lib.versions.majorMinor zfs.kernel.version == "7.3"
) "The ZFS 2.4.4 backports are restricted to Linux 7.3.";
zfs.overrideAttrs (old: {
  patchFlags = (old.patchFlags or [ "-p1" ]) ++ [ "--fuzz=0" ];
  patches = (old.patches or [ ]) ++ patches;
  # Only this patched module may bypass the upstream 7.2 compatibility ceiling.
  configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-linux-experimental" ];
  meta = old.meta // {
    broken = false;
  };
  postConfigure = (old.postConfigure or "") + ''
    for probe in HAVE_IOPS_CREATE_NO_FLAG_ARG HAVE_IOPS_CREATE_IDMAP HAVE_BVEC_ITER_OFFSET; do
      grep -qx "#define $probe 1" zfs_config.h
    done
    grep -q 'cpu_feature_enabled(X86_FEATURE_XSAVE)' include/os/linux/kernel/linux/simd_x86.h
    grep -q 'scoped_with_init_fs()' module/os/linux/spl/spl-taskq.c
    grep -q 'scoped_with_init_fs()' module/os/linux/spl/spl-thread.c
    grep -q 'scoped_with_init_fs' "$kernelSource"/include/linux/fs_struct.h
  '';
  kernelSource = "${zfs.kernel.dev}/lib/modules/${zfs.kernel.modDirVersion}/source";
  postInstall = (old.postInstall or "") + ''
    mkdir -p "$out/nix-support"
    cp zfs_config.h "$out/nix-support/zfs_config.h"
    sha256sum ${lib.escapeShellArgs (map toString patches)} > "$out/nix-support/compatibility-patches.sha256"
  '';
})
