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
          "git:github.com/aliceisjustplaying/pi-you-should-know"

          # nix-skills ships ten skills; narrow to the two actually needed
          # instead of pulling the whole repo (see skills/ below for the
          # same lesson applied to the .NET skill set).
          {
            source = "git:github.com/olafkfreund/nix-skills";
            skills = [
              "skills/nix-workflow"
              "skills/nixos-operations"
            ];
          }
        ];
      };
    };

    # Vendored skills, not a `packages` git: source: pointing at a whole
    # upstream skills repo (dotnet/skills, StefanTheCode/dotnet-ai-toolkit)
    # pulls in everything the repo ships (close to a hundred combined
    # skills), not just the ones actually wanted. These exact files were
    # hand-picked by Maksym. Discovered automatically: Pi recursively scans
    # its configDir's skills/ directory for SKILL.md files.
    home.file."${config.programs.pi-coding-agent.configDir}/skills".source = ./skills;
  };
}
