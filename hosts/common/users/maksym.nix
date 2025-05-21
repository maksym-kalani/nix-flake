{
  config,
  pkgs,
  inputs,
  ...
}: {
  users.users.maksym = {
    hashedPasswordFile = config.sops.secrets.maksym_hashed_password.path;
    isNormalUser = true;
    description = "maksym";
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "flatpak"
      "audio"
      "video"
      "plugdev"
      "input"
      "kvm"
      "qemu-libvirtd"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDVITNbszcHLlMp+cifLpMx8jGCT9IIEZlDA2Qt/0ijd maksym@DESKTOP-LAUF1N"
    ];
    packages = [inputs.home-manager.packages.${pkgs.system}.default];
  };
  home-manager.users.maksym =
    import ../../../home/maksym/${config.networking.hostName}.nix;
}
