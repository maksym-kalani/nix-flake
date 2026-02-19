{
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    mesa-demos
    vulkan-tools
    git
    wget
    curl
    tcpdump
    sops
    zfs
    rsync
    caddy
    lm_sensors
    restic
    openssh
    sysstat
  ];
}