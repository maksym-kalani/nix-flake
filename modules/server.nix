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
