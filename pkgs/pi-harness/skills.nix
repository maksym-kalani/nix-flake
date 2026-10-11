{
  fetchFromGitHub,
  runCommand,
  includeHomeManager ? false,
}:
let
  dotnet = fetchFromGitHub {
    owner = "dotnet";
    repo = "skills";
    rev = "1d40f95ed0f2cdedfa4c9b2614b7c2035a4323cb";
    hash = "sha256-vOjhGFRgjGNww38Yqw7YRVOK+Wy0qBJh6DnHCtAyaog=";
  };
  toolkit = fetchFromGitHub {
    owner = "StefanTheCode";
    repo = "dotnet-ai-toolkit";
    rev = "77af4c1ac3fb5fe165a049fe22011ac17a27f457";
    hash = "sha256-dFwsZvyMuDAizFfe6EhT7hmrmo7USREyFCdjw9OnMow=";
  };
  nixSkills = fetchFromGitHub {
    owner = "olafkfreund";
    repo = "nix-skills";
    rev = "f5c8e8b3b3255e323e5b84192d0b6ed2e79ef4f4";
    hash = "sha256-kpfzu06HYAMP/pmu3CRPQb+skIjZGByxvaUy7F08axw=";
  };
in
runCommand "pi-ready-skills" { } ''
  mkdir -p $out/skills $out/licenses
  cp -r ${dotnet}/plugins/dotnet-aspnetcore/skills/dotnet-webapi $out/skills/
  cp -r ${dotnet}/plugins/dotnet-test/skills/run-tests $out/skills/
  cp -r ${toolkit}/skills/integration-test-setup $out/skills/
  cp -r ${nixSkills}/skills/nix-workflow ${nixSkills}/skills/nixos-operations $out/skills/
  ${if includeHomeManager then "cp -r ${nixSkills}/skills/home-manager $out/skills/" else ""}
  cp ${dotnet}/LICENSE $out/licenses/dotnet-LICENSE
  cp ${toolkit}/LICENSE $out/licenses/toolkit-LICENSE
  cp ${nixSkills}/LICENSE $out/licenses/nix-skills-LICENSE
''
