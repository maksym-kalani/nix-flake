{ config, pkgs, ... }:

{
  # CIFS utilities for mounting SMB shares
  environment.systemPackages = [ pkgs.cifs-utils ];

  # SMB credentials secret
  sops.secrets.smb_credentials = {
    key = "smb_credentials";
    mode = "0400";
  };

  # Mount aigis SMB shares
  fileSystems."/mnt/aigis/users" = {
    device = "//192.168.2.50/users";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets.smb_credentials.path}"
      "uid=1000"
      "gid=100"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };

  fileSystems."/mnt/aigis/media" = {
    device = "//192.168.2.50/media";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets.smb_credentials.path}"
      "uid=1000"
      "gid=100"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };
}