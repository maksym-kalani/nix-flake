{ config, lib, mkServiceInfra, ... }:
let
  cfg = config.server.services.prowlarr;
  name = "prowlarr";
  port = 9696;
in {
  options.server.services.prowlarr = {
    enable = lib.mkEnableOption "Prowlarr indexer manager";
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (mkServiceInfra { inherit name port; })
    {
      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };
    }
  ]);
}
