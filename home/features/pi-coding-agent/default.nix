{ config, lib, pkgs, ... }:
{
  options.features.piCodingAgent.enable = lib.mkEnableOption "Pi coding agent (personal, non-work use)";

  config = lib.mkIf config.features.piCodingAgent.enable {
    programs.pi-coding-agent = {
      enable = true;

      settings = {
        defaultProvider = "ollama-cloud";
        defaultModel = "glm-5.3";
        defaultThinkingLevel = "high";
        packages = [
          "npm:pi-ollama-cloud"
          "npm:pi-quota-status"
          "npm:@narumitw/pi-plan-mode"
          "npm:@lenard9191/pi-project-profile"
          "npm:pi-subagents"
          "npm:@dietrichgebert/ponytail"
          "git:github.com/aliceisjustplaying/pi-you-should-know"
          "git:github.com/ayghri/i-have-adhd"
          "git:github.com/olafkfreund/nix-skills"
        ];
      };
    };

    # pi runs `npm install` for packages that ship a package.json
    home.packages = [ pkgs.nodejs ];

    home.file."${config.programs.pi-coding-agent.configDir}/skills".source = ./skills;
  };
}
