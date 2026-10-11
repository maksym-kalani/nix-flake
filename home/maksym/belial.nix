{ ... }:
{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/nix-tools
    ../features/ai
    ../features/pi-coding-agent
    ../features/zsh
    ../features/desktop
  ];

  features.piCodingAgent.enable = true;

  # belial-only: kitty's `kitten` SSH wrapper
  programs.zsh.shellAliases.aigis = "kitten ssh aigis";
  home.pointerCursor.enable = true;
}
