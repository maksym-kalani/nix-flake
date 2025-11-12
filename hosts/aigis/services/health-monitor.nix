{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Define the monitoring script as a separate package
  healthMonitor = pkgs.writeShellApplication {
    name = "health-monitor";
    runtimeInputs = with pkgs; [ 
      coreutils 
      procps 
      bc 
      gnugrep 
      gawk 
    ];
    text = builtins.readFile ./health-monitor.sh;
  };
in
{
  environment.systemPackages = with pkgs; [
      coreutils 
      procps 
      bc 
      gnugrep 
      gawk 
  ];
  
  systemd.services.health-monitor = {
    description = "System Health Monitor with ntfy Alerts";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${healthMonitor}/bin/health-monitor";
      User = "root";
    };
  };
  
  systemd.timers.health-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}