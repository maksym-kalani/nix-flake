{
  config,
  ...
}:
let
  ip = "192.168.2.50";
  port = 5000;
  name = "kavita";
in
{
  services.kavita = {
    enable = true;
    tokenKeyFile = config.sops.secrets.kavita_token_key.path;
    settings.Port = port;
  };

  users.users.kavita.extraGroups = [ "tankusers" ];

  networking.firewall.allowedTCPPorts = [ port ];

  services.gatus.settings.endpoints = [
    {
      name = name;
      url = "http://${ip}:${toString port}";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
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
