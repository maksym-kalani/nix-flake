{ pkgs, aigis }:
let
  inherit (pkgs) lib;
  kernelPackages = pkgs.linuxPackages_7_3;
  stable = kernelPackages.${pkgs.zfs.kernelModuleAttribute};
  patchModule = zfs: pkgs.callPackage ../../pkgs/zfs-linux-7.3 { inherit zfs; };
  patched = patchModule stable;
  rejected = zfs: !(builtins.tryEval (patchModule zfs).drvPath).success;
  tests = {
    targetKernel = lib.versions.majorMinor aigis.config.boot.kernelPackages.kernel.version == "7.3";
    stableUserspace = aigis.config.boot.zfs.package.outPath == pkgs.zfs.outPath;
    moduleSelected = aigis.config.boot.zfs.modulePackage.drvPath == patched.drvPath;
    sameSource = patched.src == pkgs.zfs.src;
    sameUserspace = patched.userspaceTools.outPath == pkgs.zfs.outPath;
    originalStillBroken = stable.meta.broken;
    scopedBrokenOverride = !patched.meta.broken;
    patchesSelected = builtins.length patched.patches == builtins.length stable.patches + 4;
    experimentalIsScoped =
      !(lib.elem "--enable-linux-experimental" stable.configureFlags)
      && lib.elem "--enable-linux-experimental" patched.configureFlags;
    rejectNewZfs = rejected (stable // { version = "2.4.5"; });
    rejectDevelopmentZfs = rejected (stable // { kernelModuleAttribute = "zfs_unstable"; });
    rejectOldKernel = rejected (
      stable
      // {
        kernel = stable.kernel // {
          version = "7.2.9";
        };
      }
    );
    rejectNewKernel = rejected (
      stable
      // {
        kernel = stable.kernel // {
          version = "7.4.0";
        };
      }
    );
    rejectUserspace = rejected (stable // { kernel = null; });
    hostAssertions = builtins.all (a: a.assertion) aigis.config.assertions;
  };
in
assert lib.assertMsg (builtins.all (v: v) (
  builtins.attrValues tests
)) "ZFS Linux 7.3 contract regression: ${builtins.toJSON tests}";
tests
