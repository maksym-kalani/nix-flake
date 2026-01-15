# Refactoring Proposal: Declarative Service Configuration

## Goal

Define aigis in one file: set the IP, domain, and enable services with simple flags like `services.karakeep.enable = true`, with service definitions accessing these as global variables.

## Proposed Refactoring

### 1. Create a server options module

**New file: `modules/server.nix`**
```nix
{ lib, ... }:
with lib;
{
  options.server = {
    ip = mkOption {
      type = types.str;
      description = "Server IP address";
    };
    domain = mkOption {
      type = types.str;
      description = "Base domain for services";
    };
    appdata = mkOption {
      type = types.str;
      default = "/mnt/tank/appdata";
      description = "Path to application data";
    };
    containerData = mkOption {
      type = types.str;
      default = "/var/lib/containers";
      description = "Path to container data";
    };
  };
}
```

### 2. Create a helper module for common service patterns

**New file: `modules/lib/mk-service.nix`**
```nix
{ config, lib, ... }:
{
  # Helper function to generate gatus endpoint + caddy vhost + firewall
  _module.args.mkServiceInfra = { name, port, healthCheck ? "[STATUS] == 200" }: {
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

    services.caddy.virtualHosts."${name}.${config.server.domain}".extraConfig = ''
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };
}
```

### 3. Convert services to proper NixOS modules

**Example: `modules/services/karakeep.nix`**
```nix
{ config, pkgs, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.karakeep;
  name = "karakeep";
  port = 3050;
in {
  options.server.services.karakeep = {
    enable = lib.mkEnableOption "Karakeep bookmark manager";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.karakeep = {
        enable = true;
        extraEnvironment = {
          PORT = toString port;
          NEXTAUTH_URL = "https://${name}.${config.server.domain}";
          DISABLE_NEW_RELEASE_CHECK = "true";
          OCR_LANGS = "eng,ukr";
        };
        environmentFile = config.sops.secrets.openai_api_key.path;
      };

      services.meilisearch = {
        enable = true;
        package = pkgs.meilisearch;
        settings.experimental_dumpless_upgrade = true;
      };
    }
  ]);
}
```

**Example container service: `modules/services/kavita.nix`**
```nix
{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.kavita;
  name = "kavita";
  port = 5000;
in {
  options.server.services.kavita = {
    enable = lib.mkEnableOption "Kavita manga/book server";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      virtualisation.oci-containers.containers.${name} = {
        image = "jvmilazz0/kavita:latest";
        ports = [ "${toString port}:5000" ];
        volumes = [
          "/mnt/tank/media/ttrpgs:/ttrpgs"
          "${config.server.containerData}/${name}:/kavita/config"
        ];
        autoStart = true;
      };
    }
  ]);
}
```

### 4. New directory structure

```
modules/
├── server.nix              # Global server options
├── lib/
│   └── mk-service.nix      # Helper for service infra
└── services/
    ├── karakeep.nix
    ├── kavita.nix
    ├── jellyfin.nix
    └── ...
```

### 5. Single host declaration file

**`hosts/aigis/default.nix`**
```nix
{ inputs, outputs, ... }:
{
  imports = [
    ../common
    ./configuration.nix
    ./zfs-logging.nix

    # Import the modules
    ../../modules/server.nix
    ../../modules/lib/mk-service.nix
    ../../modules/services/karakeep.nix
    ../../modules/services/kavita.nix
    ../../modules/services/jellyfin.nix
    # ... or import a directory with all services
  ];

  # Server configuration - all in one place
  server = {
    ip = "192.168.2.50";
    domain = "laufin.xyz";
    appdata = "/mnt/tank/appdata";
  };

  # Enable services declaratively
  server.services = {
    karakeep.enable = true;
    kavita.enable = true;
    jellyfin.enable = true;
    jellyseerr.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    # kavita.enable = false;  # disabled services just don't appear
  };

  services.podman.enable = true;
}
```

## Benefits

1. **Single source of truth** - IP, domain defined once
2. **Clean enable/disable** - `server.services.foo.enable = true`
3. **DRY** - `mkServiceInfra` eliminates repeated gatus/caddy/firewall boilerplate
4. **Discoverable** - `server.services.<tab>` shows available services
5. **Reusable** - modules can be used on other hosts with different IP/domain

## Migration Path

1. Create `modules/` directory with `server.nix` and `lib/mk-service.nix`
2. Convert one service at a time (start with a simple one like `ntfy`)
3. Import converted modules in `hosts/aigis/default.nix`
4. Remove old service files from `hosts/aigis/services/` as you migrate