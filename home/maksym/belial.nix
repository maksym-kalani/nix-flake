{ pkgs, ... }:
{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/zsh
    ../features/kitty
    ../features/desktop
  ];

  # Auto-start Hyprland on TTY1 login
  programs.zsh.profileExtra = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec start-hyprland &> /dev/null
    fi
  '';

  home.packages = with pkgs; [
    spotify
    vesktop
    telegram-desktop
    jellyfin-desktop
    obsidian
    chromium
    audacity
    bitwarden-desktop
    blueman
    rofi-network-manager
    caligula
    #wonderdraft
    nautilus
    libreoffice-fresh
    solaar
    vlc
    mission-center
    element-desktop
    papers
    loupe
    stable.claude-code
    sops
    nil
    nixd
    gnome-calendar
    gnome-calculator
    satty
    kenku-fm
    jetbrains.rider
    wonderdraft
    mcp-nixos
    devenv
    opencode
  ];
}
