{
  config,
  ...
}: let
  ip = "192.168.2.50";
  domain = "laufin.xyz";
  appdata = "/var/lib/containers/";

  db = {
    name = "rxresume-postgres";
    image = "postgres:17";
    port = {
      internal = 5432;
      external = 5432;
    };
    dbName = "rxresume";
    dbUser = "rxresume";
  };

  app = {
    name = "rxresume";
    image = "ghcr.io/reactive-resume/app:latest";
    port = {
      internal = 3000;
      external = 3300;
    };
  };
in {
  # AUTH_SECRET signs sessions; rotating it invalidates all logged-in sessions.
  # DATABASE_URL embeds the postgres password to reach the db container over the LAN IP,
  # matching this repo's convention of host-mapped container ports instead of a private podman network.
  sops.templates."rxresume-env".content = ''
    AUTH_SECRET=${config.sops.placeholder.rxresume_auth_secret}
    DATABASE_URL=postgresql://${db.dbUser}:${config.sops.placeholder.rxresume_db_password}@${ip}:${toString db.port.external}/${db.dbName}
  '';

  sops.templates."rxresume-postgres-env".content = ''
    POSTGRES_DB=${db.dbName}
    POSTGRES_USER=${db.dbUser}
    POSTGRES_PASSWORD=${config.sops.placeholder.rxresume_db_password}
  '';

  virtualisation.oci-containers.containers.${db.name} = {
    image = db.image;
    ports = ["${toString db.port.external}:${toString db.port.internal}"];
    volumes = [
      "${appdata}${db.name}:/var/lib/postgresql"
    ];
    environmentFiles = [config.sops.templates."rxresume-postgres-env".path];
    autoStart = true;
  };

  virtualisation.oci-containers.containers.${app.name} = {
    image = app.image;
    ports = ["${toString app.port.external}:${toString app.port.internal}"];
    volumes = [
      "${appdata}${app.name}/data:/app/data"
    ];
    environment = {
      PORT = "${toString app.port.internal}";
      TZ = "Europe/Kyiv";
      APP_URL = "https://${app.name}.${domain}";
    };
    environmentFiles = [config.sops.templates."rxresume-env".path];
    dependsOn = [db.name];
    autoStart = true;
  };

  networking.firewall.allowedTCPPorts = [
    db.port.external
    app.port.external
  ];

  services.gatus.settings.endpoints = [
    {
      name = app.name;
      url = "http://${ip}:${toString app.port.external}/api/health";
      interval = "1m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [
        {
          type = "ntfy";
          enabled = true;
          send-on-resolved = true;
          description = "${app.name} health check";
          failure-threshold = 3;
          success-threshold = 1;
        }
      ];
    }
  ];
}
