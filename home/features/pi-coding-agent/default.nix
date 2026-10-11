{ config, lib, ... }:
{
  options.features.piCodingAgent.enable = lib.mkEnableOption "Pi coding agent (personal, non-work use)";

  config = lib.mkIf config.features.piCodingAgent.enable {
    programs.pi-coding-agent = {
      enable = true;

      settings = {
        defaultProvider = "ollama";
        packages = [
          # Addons
          "npm:pi-ollama-cloud"
          "npm:pi-quota-status"
          "npm:@narumitw/pi-plan-mode"
          "npm:@lenard9191/pi-project-profile"
          "npm:pi-subagents"

          # Ready upstream skill snapshots
          "git:github.com/dotnet/skills"
          "git:github.com/StefanTheCode/dotnet-ai-toolkit"
          "git:github.com/olafkfreund/nix-skills"
        ];
      };
    };
  };
}
