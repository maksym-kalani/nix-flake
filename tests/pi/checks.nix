{ pkgs, home-manager }:
let
  harness = import ../../pkgs/pi-harness { inherit pkgs; };
  home =
    enabled:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../../home/features/pi-harness
        {
          home.username = "pi-test";
          home.homeDirectory = "/home/pi-test";
          home.stateVersion = "26.05";
          features.piHarness.enable = enabled;
        }
      ];
    };
  source = pkgs.lib.cleanSourceWith {
    src = ../..;
    filter =
      path: type:
      pkgs.lib.cleanSourceFilter path type
      && !(builtins.elem (baseNameOf path) [
        "evidence"
        "__pycache__"
        "obj"
        "bin"
      ]);
  };
in
{
  pi-harness =
    pkgs.runCommand "pi-harness-behavior-check"
      {
        nativeBuildInputs = with pkgs; [
          python3
          nodejs_24
          bash
          gitMinimal
          procps
          nixfmt
          statix
          ruff
        ];
        PI_TEST_RUNTIME = harness.runtime;
        PI_TEST_CONFIG = harness.config;
        PI_TEST_SAFETY = harness.safety;
      }
      ''
        cp -r ${source} source
        chmod -R u+w source
        cd source
        export HOME=$TMPDIR/home
        mkdir -p "$HOME"
        export PATH=${
          pkgs.lib.makeBinPath [
            pkgs.python3
            pkgs.bash
          ]
        }:$PATH
        python3 -m unittest discover -s tests/pi -v
        node --test tests/pi/policy.test.mjs tests/pi/extensions.test.mjs tests/pi/blockers.test.mjs tests/pi/quota.test.mjs
        ruff check pkgs/pi-harness/*.py tests/pi/*.py
        nixfmt --check flake.nix pkgs/default.nix pkgs/pi-harness/*.nix tests/pi/*.nix home/features/pi-harness/*.nix home/features/ai/default.nix home/maksym/belial.nix
        statix check pkgs/pi-harness
        touch $out
      '';
  pi-home-manager =
    assert !(pkgs.lib.any (p: p.name == "pi") (home false).config.home.packages);
    assert pkgs.lib.length (pkgs.lib.filter (p: p.name == "pi") (home true).config.home.packages) == 1;
    pkgs.runCommand "pi-home-manager-opt-in-check" { } ''
      printf '%s\n' '${builtins.unsafeDiscardStringContext (home true).activationPackage.drvPath}' > $out
    '';
  pi-api =
    pkgs.runCommand "pi-aspnet-http-acceptance"
      {
        nativeBuildInputs = [
          pkgs.dotnet-sdk_10
          pkgs.python3
          harness.checkRunner
        ];
      }
      ''
        export HOME=$TMPDIR/home
        export DOTNET_CLI_HOME=$HOME
        export DOTNET_CLI_TELEMETRY_OPTOUT=1
        mkdir -p "$HOME"
        cp -r ${./fixtures/api} api
        chmod -R u+w api
        cd api
        dotnet restore --configfile NuGet.Config --ignore-failed-sources
        pi-project-check dotnet-build
        pi-project-check dotnet-format
        mkdir -p .pi
        printf '%s\n' '${
          builtins.toJSON {
            testCommand = [
              "${pkgs.python3}/bin/python3"
              "${./api_acceptance.py}"
              "bin/Debug/net10.0/HarnessApi.dll"
            ];
          }
        }' > .pi/checks.json
        pi-project-check dotnet-test
        mkdir -p $out
        cp -r bin/Debug/net10.0 $out/api
      '';
  pi-sandbox-vm = pkgs.testers.runNixOSTest {
    name = "pi-whole-process-containment";
    nodes.machine = { pkgs, ... }: {
      users.users.pi-test = {
        isNormalUser = true;
      };
      environment.systemPackages = [
        harness.package
        pkgs.python3
      ];
      virtualisation.memorySize = 1024;
      virtualisation.cores = 2;
    };
    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")
      machine.succeed("install -m 0444 ${./sandbox_acceptance.py} /home/pi-test/acceptance.py")
      machine.succeed("su - pi-test -c 'python3 /home/pi-test/acceptance.py ${harness.package}/bin/pi'")
    '';
  };
}
