{
  config,
  pkgs,
  ...
}: let
  aigisHost = "192.168.2.50";
  automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,uid=1000,gid=100,forceuid,forcegid";
  mkShare = share: {
    device = "//${aigisHost}/${share}";
    fsType = "cifs";
    options = ["${automount_opts},credentials=${config.sops.secrets.smb_credentials.path}"];
  };
in {
  # CIFS utilities for mounting SMB shares
  environment.systemPackages = [pkgs.cifs-utils];

  # SMB credentials secret
  sops.secrets.smb_credentials = {
    key = "smb_credentials";
    mode = "0400";
  };

  # Mount aigis SMB shares
  fileSystems."/home/maksym/aigis/users" = mkShare "users";
  fileSystems."/home/maksym/aigis/media" = mkShare "media";
}
