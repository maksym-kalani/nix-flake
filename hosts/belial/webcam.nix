{
  pkgs,
  ...
}:
{
  # Add v4l-utils to system packages
  environment.systemPackages = with pkgs; [ v4l-utils ];

  # Apply webcam settings when the device is plugged in
  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", ACTION=="add", ATTR{name}=="*", \
      RUN+="${pkgs.systemd}/bin/systemctl start webcam-init.service"
  '';

  systemd.services.webcam-init = {
    description = "Apply webcam V4L2 settings";
    after = [ "dev-video0.device" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStart = pkgs.writeShellScript "webcam-init" ''
        DEV=/dev/video0
        ${pkgs.v4l-utils}/bin/v4l2-ctl -d $DEV \
          --set-ctrl brightness=128 \
          --set-ctrl contrast=128 \
          --set-ctrl saturation=128 \
          --set-ctrl white_balance_automatic=1 \
          --set-ctrl gain=255 \
          --set-ctrl power_line_frequency=0 \
          --set-ctrl sharpness=132 \
          --set-ctrl backlight_compensation=1 \
          --set-ctrl auto_exposure=1 \
          --set-ctrl exposure_time_absolute=155 \
          --set-ctrl exposure_dynamic_framerate=0 \
          --set-ctrl focus_absolute=30 \
          --set-ctrl focus_automatic_continuous=1 \
          --set-ctrl zoom_absolute=100
      '';
    };
  };
}
