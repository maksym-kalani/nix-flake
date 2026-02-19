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
}
