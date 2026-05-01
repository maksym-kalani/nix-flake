{ ... }:
{
  users.users.maksym = {
    extraGroups = [
      "tankusers"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDVITNbszcHLlMp+cifLpMx8jGCT9IIEZlDA2Qt/0ijd maksym@DESKTOP-LAUF1N"
    ];
  };
  environment.interactiveShellInit = ''
    alias rebuild='sudo nixos-rebuild switch --flake .#aigis'
    alias zfs-users='sudo fuser -vm /mnt/tank'
  '';
}
