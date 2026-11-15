{
  config,
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
      assertion =
        config.boot.zfs.package.version == module.version
        && config.boot.zfs.package.src == module.src
        && config.boot.zfs.package.outPath == module.userspaceTools.outPath;
      message = "Aigis ZFS userspace and kernel module must come from the same stable package.";
    }
  ];
}
