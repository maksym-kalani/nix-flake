{ config, lib, ... }:
{
  _module.args.mkServiceInfra = {
    name,
    port,
    healthCheck ? "[STATUS] == 200",
    extraCaddyConfig ? "",
    subdomain ? name
  }: {
    networking.firewall.allowedTCPPorts = [ port ];

    services.gatus.settings.endpoints = [{
      name = name;
      url = "http://${config.server.ip}:${toString port}";
      interval = "1m";
      conditions = [ healthCheck ];
      alerts = [{
        type = "ntfy";
        enabled = true;
        send-on-resolved = true;
        description = "${name} health check";
        failure-threshold = 3;
        success-threshold = 1;
      }];
    }];

    services.caddy.virtualHosts."${subdomain}.${config.server.domain}".extraConfig =
      if extraCaddyConfig != "" then extraCaddyConfig
      else ''
        reverse_proxy 127.0.0.1:${toString port}
      '';
  };

  _module.args.mkContainerService = {
    name,
    image,
    port,
    internalPort ? port,
    volumes ? [],
    environment ? {},
    extraOptions ? [],
    healthCheck ? "[STATUS] == 200",
    extraCaddyConfig ? "",
    subdomain ? name
  }: lib.mkMerge [
    {
      virtualisation.oci-containers.containers.${name} = {
        inherit image environment extraOptions;
        ports = [ "${toString port}:${toString internalPort}" ];
        volumes = volumes;
        autoStart = true;
      };

      networking.firewall.allowedTCPPorts = [ port ];

      services.gatus.settings.endpoints = [{
        name = name;
        url = "http://${config.server.ip}:${toString port}";
        interval = "1m";
        conditions = [ healthCheck ];
        alerts = [{
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }];
      }];

      services.caddy.virtualHosts."${subdomain}.${config.server.domain}".extraConfig =
        if extraCaddyConfig != "" then extraCaddyConfig
        else ''
          reverse_proxy 127.0.0.1:${toString port}
        '';
    }
  ];
}
