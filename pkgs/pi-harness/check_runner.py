"""Concrete project checks; no installs, restore, daemon forwarding or deployment."""

import json
import os
import subprocess
import sys
from pathlib import Path


def run(argv):
    return subprocess.run(argv, check=False, timeout=600).returncode


def main(kind):
    config_path = Path(".pi/checks.json")
    config = json.loads(config_path.read_text()) if config_path.exists() else {}
    if kind == "dotnet-test":
        argv = config.get("testCommand")
        if argv is None:
            if config.get("testRunner", "vstest") != "vstest":
                raise ValueError(
                    "Native MTP needs an explicit project-correct testCommand argv"
                )
            argv = ["dotnet", "test", "--no-restore", "--no-build"]
        if (
            not isinstance(argv, list)
            or not argv
            or not all(isinstance(x, str) and x for x in argv)
        ):
            raise ValueError("testCommand must be a nonempty argv array")
        return run(argv)
    if kind == "dotnet-build":
        return run(
            [
                "dotnet",
                "build",
                "--no-restore",
                "-p:RunAnalyzersDuringBuild=true",
                "-warnaserror",
            ]
        )
    if kind == "dotnet-format":
        return run(["dotnet", "format", "--no-restore", "--verify-no-changes"])
    if kind == "nix-lint":
        paths = (
            subprocess.check_output(
                [
                    "git",
                    "ls-files",
                    "-z",
                    "--cached",
                    "--others",
                    "--exclude-standard",
                    "*.nix",
                ]
            )
            .decode()
            .split("\0")
        )
        paths = sorted({p for p in paths if p and Path(p).is_file()})
        if not paths:
            raise ValueError("No tracked/unignored Nix sources to check")
        code = run(["nixfmt", "--check", *paths])
        return code or run(["statix", "check", "."])
    if kind in ["nix-eval", "nix-build"]:
        if os.environ.get("PI_CODING_AGENT_DIR") == "/state/agent":
            raise ValueError(
                "BLOCKED: Nix realization/eval needs the explicit outside-sandbox human workflow; daemon socket is not forwarded"
            )
        key = "nixEvalTargets" if kind == "nix-eval" else "nixBuildTargets"
        targets = config.get(key)
        if (
            not isinstance(targets, list)
            or not targets
            or not all(isinstance(x, str) and x for x in targets)
        ):
            raise ValueError(
                f"Configure explicit relevant {key} in .pi/checks.json; no full host build by default"
            )
        for target in targets:
            if kind == "nix-eval":
                code = run(
                    ["nix", "eval", "--offline", "--no-write-lock-file", ".#" + target]
                )
            else:
                code = run(
                    [
                        "nix",
                        "build",
                        "--offline",
                        "--no-write-lock-file",
                        "--no-link",
                        ".#" + target,
                    ]
                )
            if code:
                return code
        return 0
    raise ValueError("Unknown check tier")


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1]))
    except (ValueError, OSError, subprocess.SubprocessError, IndexError) as error:
        print(f"pi-project-check: {error}", file=sys.stderr)
        sys.exit(78)
