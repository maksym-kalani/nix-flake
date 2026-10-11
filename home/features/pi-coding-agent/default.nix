{ config, lib, ... }:
{
  options.features.piCodingAgent.enable = lib.mkEnableOption "Pi coding agent (personal, non-work use)";

  config = lib.mkIf config.features.piCodingAgent.enable {
    programs.pi-coding-agent = {
      enable = true;

      settings = {
        defaultProvider = "ollama";
        packages = [
          "npm:pi-ollama-cloud"
          "npm:pi-quota-status"
          "npm:@narumitw/pi-plan-mode"
          "npm:@lenard9191/pi-project-profile"
          "npm:pi-subagents"
          "git:github.com/aliceisjustplaying/pi-you-should-know"
          "git:github.com/ayghri/i-have-adhd"
          "git:github.com/olafkfreund/nix-skills"
        ];
      };
    };

    home.file."${config.programs.pi-coding-agent.configDir}/skills".source = ./skills;
  };
}
