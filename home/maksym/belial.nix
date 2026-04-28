{ ... }:
{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/nix-tools
    ../features/ai
    ../features/zsh
    ../features/desktop
  ];

  # belial-only: kitty's `kitten` SSH wrapper
  programs.zsh.shellAliases.aigis = "kitten ssh aigis";
}
