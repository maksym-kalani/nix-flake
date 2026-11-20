{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.features.piCodingAgent.enable = lib.mkEnableOption "Pi coding agent (personal, non-work use)";

  config = lib.mkIf config.features.piCodingAgent.enable {
    programs.pi-coding-agent = {
      enable = true;

      settings = {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-6.1-sol";
        defaultThinkingLevel = "high";
        packages = [
          "npm:pi-ollama-cloud"
          "npm:pi-quota-status"
          "npm:pi-model-pick"
          "npm:pi-next-prompt"
          "npm:@narumitw/pi-plan-mode"
          "npm:@lenard9191/pi-project-profile"
          "npm:pi-subagents"
          "npm:@dietrichgebert/ponytail"
          "git:github.com/aliceisjustplaying/pi-you-should-know"
          "git:github.com/ayghri/i-have-adhd"
          "git:github.com/olafkfreund/nix-skills"
        ];
      };

      # Hermes' -900k suffix is an alias, not a Codex model ID.
      models.providers.openai-codex.modelOverrides."gpt-6.1-sol".contextWindow = 900000;
    };

    # pi runs `npm install` for packages that ship a package.json
    home.packages = [ pkgs.nodejs ];

    home.file."${config.programs.pi-coding-agent.configDir}/skills".source = ./skills;
  };
}
