{
  pkgs,
  lib,
  ...
}:
let
  ntfyTopicSmart = "http://localhost:8081/homelab";
in
{
  # SMARTD notifier script — posts SMART alerts to ntfy
  environment.etc."smartd-ntfy.sh".text = lib.mkForce ''
    #!${pkgs.bash}/bin/bash
    device="$SMARTD_DEVICE"
    message="$SMARTD_MESSAGE"
    ${pkgs.curl}/bin/curl -s -X POST ${ntfyTopicSmart} \
      -d "SMART alert on device '$device': $message"
  '';
  environment.etc."smartd-ntfy.sh".mode = "0755";

  # Enable smartd with ntfy notifications (ZFS pool health is handled by health-monitor)
  services.smartd = {
    enable = true;
    autodetect = true;
    devices = [
      {
        device = "DEVICESCAN";
        options = ''-H -o on -S on -a -m "" -M exec "/etc/smartd-ntfy.sh"'';
      }
    ];
  };
}
