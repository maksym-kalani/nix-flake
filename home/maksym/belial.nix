{
  inputs,
  ...
}:
{
  imports = [
    ./home.nix
    ../common
    ../features/cli
    ../features/nix-tools
    ../features/claude-code
    ../features/pi-coding-agent
    ../features/zsh
    ../features/desktop

    # Hermes Agent (desktop app connects to the remote Hermes backend)
    inputs.hermes-agent.homeManagerModules.default
  ];

  features.piCodingAgent.enable = true;

  programs.hermes-agent = {
    # `hermes` CLI on PATH + HERMES_HOME for the session
    enable = true;
    # Hermes Desktop (Electron) with a launcher entry
    desktop.enable = true;
  };

  # belial-only: kitty's `kitten` SSH wrapper
  programs.zsh.shellAliases.aigis = "kitten ssh aigis";
  home.pointerCursor.enable = true;
}
