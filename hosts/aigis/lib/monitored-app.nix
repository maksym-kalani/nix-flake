{ lib }:
{
  name,
  url ? null,
  icon ? null,
  description ? null,
  isPinned ? true,
  ip ? "192.168.2.50",
  port ? null,
  gatusName ? name,
  enableFlame ? true,
  enableGatus ? true,
}:
{
  services =
    lib.optionalAttrs enableFlame {
      flame.apps = [
        (
          { inherit name url icon isPinned; }
          // lib.optionalAttrs (description != null) { inherit description; }
        )
      ];
    }
    // lib.optionalAttrs enableGatus {
      gatus.settings.endpoints = [
        {
          name = gatusName;
          url = "http://${ip}:${toString port}";
          interval = "1m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [
            {
              type = "ntfy";
              enabled = true;
              send-on-resolved = true;
              description = "${gatusName} health check";
              failure-threshold = 3;
              success-threshold = 1;
            }
          ];
        }
      ];
    };
}
