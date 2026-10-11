{
  pkgs,
  includeHomeManager ? false,
  extraTools ? [ ],
}:
let
  inherit (pkgs) lib;
  runtime = pkgs.callPackage ./runtime.nix { };
  skills = pkgs.callPackage ./skills.nix { inherit includeHomeManager; };
  safety = pkgs.runCommand "pi-harness-admission" { } ''
    mkdir -p $out
    cp ${./policy.mjs} $out/policy.mjs
    substitute ${./safety.ts} $out/safety.ts --replace-fail '@RUNTIME@' '${runtime}'
    substitute ${./delegator.ts} $out/delegator.ts --replace-fail '@RUNTIME@' '${runtime}'
  '';
  checkRunner = pkgs.writeShellScriptBin "pi-project-check" ''
    exec ${pkgs.python3}/bin/python3 ${./check_runner.py} "$@"
  '';
  childBinary = pkgs.writeShellScriptBin "pi-child" ''
    exec ${runtime}/bin/pi-internal --approve "$@"
  '';
  tools = pkgs.buildEnv {
    name = "pi-sandbox-tools";
    paths =
      (with pkgs; [
        bash
        coreutils
        findutils
        gnugrep
        gnused
        gawk
        gitMinimal
        ripgrep
        fd
        python3
        nodejs_24
        procps
        nix
        nixfmt
        statix
        cacert
      ])
      ++ [
        checkRunner
        childBinary
      ]
      ++ extraTools;
  };
  nm = "${runtime}/lib/pi/node_modules";
  coreSkills = map (name: "${skills}/skills/${name}") (
    [
      "dotnet-webapi"
      "run-tests"
      "integration-test-setup"
      "nix-workflow"
      "nixos-operations"
    ]
    ++ lib.optional includeHomeManager "home-manager"
  );
  childExtensions = [
    "${nm}/pi-ollama-cloud/index.ts"
    "${safety}/safety.ts"
  ];
  profile = name: tools: {
    description = "Bounded ${name}; explicit parent-selected model, no recursion";
    model = null;
    thinking = "medium";
    deadlineMs = 600000;
    prompt = "${nm}/@mostlyworks/pi-delegator/agents/${name}.md";
    inherit tools;
    skills = coreSkills;
    extensions = childExtensions;
  };
  template = pkgs.writeText "pi-harness-template.json" (
    builtins.toJSON {
      "settings.json" = {
        defaultProvider = "ollama-cloud";
        defaultModel = "glm-5.3";
        defaultThinkingLevel = "medium";
        enabledModels = [
          "ollama-cloud/glm-5.3"
          "openai-codex/gpt-6.1-sol"
        ];
        packages = [ ];
        extensions = [ ];
        skills = [ ];
        prompts = [ ];
        telemetry = {
          enabled = false;
        };
      };
      "ollama-cloud.json" = {
        webTools = false;
        usageStatus = true;
      };
      "pi-quota-status/config.json" = {
        version = 1;
        refreshIntervalMs = 60000;
        warningThreshold = 25;
        criticalThreshold = 10;
        adapters = [
          {
            name = "no-estimated-fallback";
            type = "generic";
            enabled = false;
            provider = "openai-codex";
            models = [ "gpt-6.1-sol" ];
          }
        ];
      };
      "pi-plan-mode.json" = {
        thinkingLevel = "inherit";
        defaultPlanTools = [
          "read"
          "grep"
          "find"
          "ls"
        ];
        implementationPlanRetention = "keep";
      };
      "project-profile/config.json" = {
        verify = {
          enabled = true;
          maxRepairRounds = 2;
          runTests = "allow";
          runBuild = "allow";
          headless = true;
          guard = true;
          perTurn = true;
          concurrency = 1;
          summarizeOnGiveUp = false;
        };
        profile = {
          inject = true;
          inlineInstructionFiles = false;
          scopedInstructions = true;
        };
      };
      "pi-delegator.json".profiles = {
        scout = profile "scout" [
          "read"
          "grep"
          "find"
          "ls"
        ];
        reviewer = profile "reviewer" [
          "read"
          "grep"
          "find"
          "ls"
        ];
        oracle = null;
        tester = profile "tester" [
          "read"
          "grep"
          "find"
          "ls"
          "bash"
        ];
        worker = profile "worker" [
          "read"
          "grep"
          "find"
          "ls"
          "bash"
          "edit"
          "write"
        ];
      };
    }
  );
  prompt = pkgs.writeText "pi-harness-workflow.md" ''
    Start code changes with /plan. A human reviews and explicitly Implements the completed plan.
    Use only ollama-cloud/glm-5.3 or openai-codex/gpt-6.1-sol; parent selects an exact model for every delegate call.
    One delegate at a time, ten minute deadline; never recurse or schedule. One writer per checkout.
    Run project-correct checks; no install, restore, switch, deploy or host daemon exceptions inside the sandbox.
    Do not claim analyzer coverage unless the project configures analyzers; never call blocked checks successful.
    Testcontainers requires a separate isolated runtime, never the host Docker/Podman socket.
  '';
  config = pkgs.writeText "pi-harness-launch.json" (
    builtins.toJSON {
      bwrap = "${pkgs.bubblewrap}/bin/bwrap";
      inherit
        template
        runtime
        tools
        prompt
        ;
      certs = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      probe = ../../tests/pi/sandbox_probe.py;
      skills = coreSkills;
      extensions = [
        "${safety}/safety.ts"
        "${nm}/pi-ollama-cloud/index.ts"
        "${nm}/pi-quota-status/src/index.ts"
        "${nm}/@narumitw/pi-plan-mode/dist/index.ts"
        "${safety}/delegator.ts"
      ];
    }
  );
  launcher = pkgs.writeShellScriptBin "pi" ''
    exec ${pkgs.python3}/bin/python3 ${./launcher.py} --config ${config} "$@"
  '';
in
{
  inherit
    runtime
    skills
    safety
    tools
    template
    config
    checkRunner
    ;
  package = launcher.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      inherit
        runtime
        skills
        safety
        tools
        template
        config
        ;
    };
    meta = (old.meta or { }) // {
      description = "Fail-closed sandboxed personal Pi harness (#239)";
      mainProgram = "pi";
    };
  });
}
