{ inputs, lib, ... }:
{
  home-manager.sharedModules = lib.singleton inputs.vicinae.homeManagerModules.default;
}
