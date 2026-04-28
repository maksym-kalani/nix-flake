{ lib, config, ... }:
{
  programs.zsh.profileExtra = lib.mkIf config.programs.zsh.enable ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec start-hyprland &> /dev/null
    fi
  '';
}
