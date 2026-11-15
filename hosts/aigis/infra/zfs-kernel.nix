{
  config,
  lib,
  pkgs,
  ...
}:
let
  tools = pkgs.zfs;
  module = pkgs.callPackage ../../../pkgs/zfs-linux-7.3 {
    zfs = config.boot.kernelPackages.${tools.kernelModuleAttribute};
  };
in
{
  boot.kernelPackages = pkgs.linuxPackages_7_3;
  boot.zfs = {
    package = tools;
    modulePackage = module;
  };
  assertions = [
    {
      assertion = tools.version == "2.4.4" && tools.kernelModuleAttribute == "zfs_2_4";
      message = "Aigis requires stable ZFS 2.4.4 until the Linux 7.3 workaround is revalidated or removed.";
    }
    {
      assertion =
        config.boot.zfs.package.version == module.version
        && config.boot.zfs.package.src == module.src
        && config.boot.zfs.package.outPath == module.userspaceTools.outPath;
      message = "Aigis ZFS userspace and kernel module must come from the same stable package.";
    }
    {
      assertion = lib.versions.majorMinor config.boot.kernelPackages.kernel.version == "7.3";
      message = "Aigis ZFS compatibility backports must not be reused outside Linux 7.3.";
    }
  ];
}
