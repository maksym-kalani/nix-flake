{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    rtk
    nodejs
  ];

  programs.opencode = {
    enable = true;

    settings = {
      model = "anthropic/claude-opus-4-6";
      shell = "/bin/zsh";
      instructions = [
        "~/.config/opencode/instructions/main.md"
        "~/.config/opencode/instructions/rtk.md"
      ];
      skills.paths = [
        "~/.config/opencode/skills/dotnet"
        "~/.config/opencode/skills/ecc"
        "~/.config/opencode/skills/karpathy"
      ];
    };

    agents = ./opencode/agents;
    skills = ./opencode/skills;
  };

  xdg.configFile = {
    "opencode/instructions".source = ./opencode/instructions;
    "opencode/rules".source = ./opencode/rules;
    "opencode/plugins".source = ./opencode/plugins;
  };
}
