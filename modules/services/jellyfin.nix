{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.jellyfin;
  name = "jellyfin";
  port = 8096;
in {
  options.server.services.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.jellyfin.enable = true;
      users.users.jellyfin.extraGroups = [ "tankusers" "render" "video" ];
    }
  ]);
}
