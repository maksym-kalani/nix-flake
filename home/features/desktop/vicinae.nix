{ config, ... }:
{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  stylix.targets.vicinae.colors.override = {
    base01 = config.lib.stylix.colors.base00;
  };
}
