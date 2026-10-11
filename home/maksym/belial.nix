{ ... }:
{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/nix-tools
    ../features/ai
    ../features/pi-harness
    ../features/zsh
    ../features/desktop
  ];

  features.piHarness.enable = true;

  # belial-only: kitty's `kitten` SSH wrapper
  programs.zsh.shellAliases.aigis = "kitten ssh aigis";
  home.pointerCursor.enable = true;
}
