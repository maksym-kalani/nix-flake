{ config, pkgs, ... }:
{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
    package = pkgs.vicinae;
  };

  stylix.targets.vicinae.colors.override = {
    base01 = config.lib.stylix.colors.base00;
  };

  stylix.targets.vicinae.opacity.enable = true;
}
