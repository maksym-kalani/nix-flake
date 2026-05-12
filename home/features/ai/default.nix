{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    opencode
    rtk
  ];
}
