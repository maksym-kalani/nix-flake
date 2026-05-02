{
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.extraPools = ["tank2"];
  boot.zfs.forceImportRoot = false;
  services.zfs.autoScrub.enable = true;
}