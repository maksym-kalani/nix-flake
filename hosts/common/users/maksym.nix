{
  config,
  pkgs,
  inputs,
  ...
}: {
  sops.secrets.maksym_hashed_password = {};

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
    packages = [inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default];
  };
  home-manager.users.maksym =
    import ../../../home/maksym/${config.networking.hostName}.nix;
}
