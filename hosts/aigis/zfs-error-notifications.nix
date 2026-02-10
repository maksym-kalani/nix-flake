{
  config,
  pkgs,
  lib,
  ...
}: let
  # Replace these with your real ntfy.sh topics/URLs:
  ntfyTopicZfs = "http://localhost:8081/homelab";
  ntfyTopicSmart = "http://localhost:8081/homelab";
in {
  ############################################################################
  # 1) SMARTD Notifier Script                                                 #
  ############################################################################

  environment.etc."smartd-ntfy.sh".text = lib.mkForce ''
    #!${pkgs.bash}/bin/bash
    #
    # smartd invokes us with SMARTD_DEVICE and SMARTD_MESSAGE set.
    device="$SMARTD_DEVICE"
    message="$SMARTD_MESSAGE"
    ${pkgs.curl}/bin/curl -s -X POST ${ntfyTopicSmart} \
      -d "SMART alert on device '$device': $message"
  '';
  environment.etc."smartd-ntfy.sh".mode = "0755";

  ############################################################################
  # 2) Enable smartd & Point It at Our Notifier                               #
  ############################################################################

  services.smartd = {
    enable = true; # Turn on smartd itself
    autodetect = true; # Monitor all disks automatically

    # “devices” must be a list of records; each record has:
    #   • device  = string
    #   • options = single string of all flags (not a list)
    devices = [
      {
        device = "DEVICESCAN";
        options = ''-H -o on -S on -a -m "" -M exec "/etc/smartd-ntfy.sh"'';
        # Explanation of flags:
        #   -H               ⇒ report health status
        #   -o on            ⇒ enable offline data collection
        #   -S on            ⇒ enable automatic SMART save
        #   -a               ⇒ shorthand for “all checks”
        #   -m ""            ⇒ disable email (we use curl + ntfy.sh)
        #   -M exec "<path>" ⇒ on any SMART event, run our helper script
      }
    ];
  };

  ############################################################################
  # 3) ZFS Health Check Script + Timer                                        #
  ############################################################################

  # 3.a) Drop in a shell script that checks each pool’s health; if any pool
  #     is not “ONLINE”, send a POST to ntfyTopicZfs.
  environment.etc."zfs-health-check.sh".text = lib.mkForce ''
    #!${pkgs.bash}/bin/bash
    #
    # Loop through every ZFS pool; if health != ONLINE, POST to ntfy.sh:
    for pool in $(${pkgs.zfs}/bin/zpool list -H -o name); do
      status=$(${pkgs.zfs}/bin/zpool get -H -o value health "$pool")
      if [ "$status" != "ONLINE" ]; then
        ${pkgs.curl}/bin/curl -s -X POST ${ntfyTopicZfs} \
          -d "ZFS pool '$pool' health is: $status"
      fi
    done
  '';
  environment.etc."zfs-health-check.sh".mode = "0755";

  # 3.b) Define a oneshot service that runs the ZFS‐check script:
  systemd.services."zfs-health-check" = {
    description = "Check ZFS pool health and send ntfy notification";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/zfs-health-check.sh";
    };
    wantedBy = ["multi-user.target"];
  };

  # 3.c) Attach a timer that fires hourly *and* points back at the above service.
  #       Note: the “Unit” must live inside timerConfig, not at top‐level.
  systemd.timers."zfs-health-check" = {
    description = "Run ZFS health check every hour";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly"; # Every hour on the hour :contentReference[oaicite:2]{index=2}
      Persistent = true; # Catch up if the machine was off
      Unit = "zfs-health-check.service";
    };
  };
}
