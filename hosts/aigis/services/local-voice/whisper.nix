{ ... }:
let
  ip = "192.168.2.50";
  port = 10300;
  name = "whisper";
in
{
  services.wyoming.faster-whisper.servers.${name} = {
    enable = true;
    uri = "tcp://0.0.0.0:${toString port}";
    sttLibrary = "faster-whisper";
    # large-v3 on CPU took 26-150s per live utterance on aigis (Ryzen 5 PRO 4650G),
    # leaving the satellite yellow-listening long after speech ended. small-int8
    # transcribes the same clip ~5x faster with acceptable Ukrainian accuracy.
    model = "small-int8";
    language = "uk";
    device = "cpu";
    beamSize = 1;
    extraArgs = [ "--cpu-threads" "6" ];
    zeroconf.enable = false;
  };

  networking.firewall.allowedTCPPorts = [ port ];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "tcp://${ip}:${toString port}";
      interval = "1m";
      conditions = [
        "[CONNECTED] == true"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
