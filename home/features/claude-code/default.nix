{
  lib,
  pkgs,
  ...
}:
let
  nixSkills = pkgs.fetchFromGitHub {
    owner = "olafkfreund";
    repo = "nix-skills";
    rev = "f5c8e8b3b3255e323e5b84192d0b6ed2e79ef4f4";
    hash = "sha256-kpfzu06HYAMP/pmu3CRPQb+skIjZGByxvaUy7F08axw=";
  };
  iHaveAdhd = pkgs.fetchFromGitHub {
    owner = "ayghri";
    repo = "i-have-adhd";
    rev = "1ecea1993b7fce257ffbd686c070948b5e07eda6";
    hash = "sha256-GTqrnZxQvzo/ogAuUrffkOaMK1BYm/4rAZsnfmDt7DU=";
  };
  ponytail = pkgs.fetchzip {
    url = "https://registry.npmjs.org/@dietrichgebert/ponytail/-/ponytail-5.3.2.tgz";
    hash = "sha256-hx8sfsn5sHop9L3IgtUfL2ylBgE5gfgQi96wmvCfMnY=";
  };

  skillsFrom =
    dir:
    lib.mapAttrs (name: _: "${dir}/${name}") (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)
    );
in
{
  programs.claude-code = {
    enable = true;

    skills =
      (skillsFrom ../pi-coding-agent/skills)
      // (skillsFrom "${nixSkills}/skills")
      // (skillsFrom "${iHaveAdhd}/skills")
      // (skillsFrom "${ponytail}/skills");
  };
}
