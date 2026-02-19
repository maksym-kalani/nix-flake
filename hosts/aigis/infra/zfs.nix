{
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.extraPools = ["tank2"];
  services.zfs.autoScrub.enable = true;
}