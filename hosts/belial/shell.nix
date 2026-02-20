{ pkgs, ... }:
{
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Required for xdg.portal when using home-manager with useUserPackages
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];
  environment.interactiveShellInit = ''
    alias rebuild='sudo nixos-rebuild switch --flake .#belial'
  '';

  services.getty.greetingLine = ""; # suppress default
  services.getty.helpLine = "";

  environment.etc."issue".text = ''
    \e[H\e[2J\e[3J
    \e[1;34m          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖             \e[1;31m\e[0m
    \e[1;34m          ▜███▙       ▜███▙  ▟███▛             \e[1;31m\e[0m
    \e[1;34m           ▜███▙       ▜███▙▟███▛              \e[1;31m\e[0m
    \e[1;34m            ▜███▙       ▜██████▛               \e[1;31m\e[0m
    \e[1;34m     ▟█████████████████▙ ▜████▛     ▟▙         \e[1;31m\e[0m
    \e[1;34m    ▟███████████████████▙ ▜███▙    ▟██▙        \e[1;31m@@@@@@@   @@@@@@@@  @@@       @@@   @@@@@@   @@@\e[0m
    \e[1;34m           ▄▄▄▄▖           ▜███▙  ▟███▛        \e[1;31m@@@@@@@@  @@@@@@@@  @@@       @@@  @@@@@@@@  @@@\e[0m
    \e[1;34m          ▟███▛             ▜██▛ ▟███▛         \e[1;31m@@!  @@@  @@!       @@!       @@!  @@!  @@@  @@!\e[0m
    \e[1;34m         ▟███▛               ▜▛ ▟███▛          \e[1;31m!@   @!@  !@!       !@!       !@!  !@!  @!@  !@!\e[0m
    \e[1;34m▟███████████▛                  ▟██████████▙    \e[1;31m@!@!@!@   @!!!:!    @!!       !!@  @!@!@!@!  @!!\e[0m
    \e[1;34m▜██████████▛                  ▟███████████▛    \e[1;31m!!!@!!!!  !!!!!:    !!!       !!!  !!!@!!!!  !!!\e[0m
    \e[1;34m      ▟███▛ ▟▙               ▟███▛             \e[1;31m!!:  !!!  !!:       !!:       !!:  !!:  !!!  !!:\e[0m
    \e[1;34m     ▟███▛ ▟██▙             ▟███▛              \e[1;31m:!:  !:!  :!:        :!:      :!:  :!:  !:!   :!:\e[0m
    \e[1;34m    ▟███▛  ▜███▙           ▝▀▀▀▀               \e[1;31m :: ::::   :: ::::   :: ::::   ::  ::   :::   :: ::::\e[0m
    \e[1;34m    ▜██▛    ▜███▙ ▜██████████████████▛         \e[1;31m:: : ::   : :: ::   : :: : :  :     :   : :  : :: : :\e[0m
    \e[1;34m     ▜▛     ▟████▙ ▜████████████████▛          \e[1;31m\e[0m
    \e[1;34m           ▟██████▙         ▜███▙              \e[1;31m\e[0m
    \e[1;34m          ▟███▛▜███▙         ▜███▙             \e[1;31m\e[0m
    \e[1;34m         ▟███▛  ▜███▙         ▜███▙            \e[1;31m\e[0m
    \e[1;34m         ▝▀▀▀    ▀▀▀▀▘         ▀▀▀▘            \e[1;31m\e[0m

  '';
}
