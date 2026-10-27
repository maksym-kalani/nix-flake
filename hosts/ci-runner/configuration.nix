{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # boots under both SeaBIOS and OVMF
  };

  networking.hostName = "ci-runner";
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  services.qemuGuest.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.maksym = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDVITNbszcHLlMp+cifLpMx8jGCT9IIEZlDA2Qt/0ijd maksym@DESKTOP-LAUF1N"
    ];
  };
  security.sudo.wheelNeedsPassword = false; # key-only host, no password hash to decrypt

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "maksym"
    ];
  };

  system.stateVersion = "26.11";
}
