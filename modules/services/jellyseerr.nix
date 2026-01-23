{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.jellyseerr;
  name = "jellyseerr";
  port = 5055;
in {
  options.server.services.jellyseerr = {
    enable = lib.mkEnableOption "Jellyseerr media request manager";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.jellyseerr = {
        enable = true;
        openFirewall = true;
      };
    }
  ]);
}
