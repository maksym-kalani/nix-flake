"""Fail-closed Pi containment. No credential values are read by this launcher."""

import argparse
import fcntl
import hashlib
import json
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path


def no_symlinks(path):
    path = Path(os.path.abspath(path))
    for part in [path, *path.parents]:
        if part.is_symlink():
            raise ValueError("symlink path is not permitted")
    return path


def private_directory(path):
    path = no_symlinks(path)
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = path.stat()
    if info.st_uid != os.getuid() or info.st_mode & 0o077:
        raise ValueError("agent state must be owned by the current user and mode 0700")
    return path


def validate_project(project, state, home):
    project = no_symlinks(project)
    if not project.is_dir():
        raise ValueError("project must be an existing directory")
    if any(
        project == p or project in p.parents or p in project.parents
        for p in [
            Path(state),
            *map(
                Path,
                [
                    "/nix",
                    "/proc",
                    "/dev",
                    "/run",
                    "/etc",
                    "/sys",
                    "/usr",
                    "/var",
                    "/boot",
                    "/bin",
                    "/sbin",
                    "/lib",
                    "/lib64",
                ],
            ),
        ]
    ):
        raise ValueError("project overlaps a protected mount or agent state")
    if project == Path(home) or project in Path(home).parents:
        raise ValueError("a full host home/root cannot be a project")
    # A linked checkout exposes shared Git metadata or breaks when mapped to /project.
    # Reject rather than bind its parent (which could expose other checkouts/secrets).
    git = project / ".git"
    if git.is_symlink() or (git.exists() and not git.is_dir()):
        raise ValueError("linked .git worktrees unsupported; use an independent clone")
    for ancestor in project.parents:
        if (ancestor / ".git").exists():
            raise ValueError("select the repository root, not a nested directory")
    if (git / "objects/info/alternates").exists() or (git / "commondir").exists():
        raise ValueError("external shared Git object directories unsupported")
    reject_sockets(project)
    return project


def reject_sockets(root):
    # A bind-mounted AF_UNIX socket is a capability even without /run mounted.
    # Do not follow symlinks; external targets are invisible in the namespace.
    for directory, dirs, files in os.walk(root, followlinks=False):
        for name in dirs + files:
            if stat.S_ISSOCK((Path(directory) / name).lstat().st_mode):
                raise ValueError("existing Unix sockets cannot be exposed to Pi")


def checkout_state(root, project):
    identity = hashlib.sha256(os.fsencode(str(project))).hexdigest()
    return root / "checkouts" / identity / "mutable"


def project_settings(state, templates):
    """Reconcile managed keys, preserving unrelated preferences and runtime state."""
    for name, template in templates.items():
        target = state / name
        no_symlinks(target.parent)
        target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        if target.is_symlink() or (
            target.exists() and not stat.S_ISREG(target.stat().st_mode)
        ):
            raise ValueError("managed settings must be a regular non-symlink file")
        current = json.loads(target.read_text()) if target.exists() else {}
        current.update(template)
        fd, tmp = tempfile.mkstemp(prefix=".projection-", dir=target.parent)
        try:
            with os.fdopen(fd, "w") as stream:
                json.dump(current, stream, indent=2)
                stream.write("\n")
            os.replace(tmp, target)
        finally:
            if os.path.exists(tmp):
                os.unlink(tmp)


def sandbox_argv(project, state, cfg, args, offline=False, probe=False):
    argv = [
        cfg["bwrap"],
        "--unshare-user",
        "--unshare-pid",
        "--unshare-ipc",
        "--unshare-uts",
        "--unshare-cgroup",
        "--disable-userns",
        "--die-with-parent",
        "--new-session",
        "--cap-drop",
        "ALL",
        "--clearenv",
        "--tmpfs",
        "/",
        "--ro-bind",
        "/nix/store",
        "/nix/store",
        "--ro-bind",
        cfg["tools"],
        "/tools",
        "--proc",
        "/proc",
        "--dev",
        "/dev",
        "--tmpfs",
        "/tmp",
        "--dir",
        "/home/pi",
        "--dir",
        "/home/pi/.pi",
        "--bind",
        str(project),
        "/project",
        "--bind",
        str(state),
        "/state",
        "--symlink",
        "/state/agent",
        "/home/pi/.pi/agent",
        "--symlink",
        "/state/cache",
        "/home/pi/.cache",
        "--symlink",
        "/state/nuget",
        "/home/pi/.nuget",
        "--symlink",
        "/tools/bin",
        "/bin",
        "--dir",
        "/etc",
        "--dir",
        "/etc/ssl/certs",
    ]
    if offline:
        argv += ["--unshare-net"]
    for source, target in [
        ("/etc/resolv.conf", "/etc/resolv.conf"),
        ("/etc/hosts", "/etc/hosts"),
    ]:
        if Path(source).exists():
            argv += ["--ro-bind", str(Path(source).resolve()), target]
    if cfg.get("certs"):
        argv += ["--ro-bind", cfg["certs"], "/etc/ssl/certs/ca-certificates.crt"]
    env = {
        "HOME": "/home/pi",
        "PATH": "/tools/bin",
        "SHELL": "/bin/bash",
        "PI_CODING_AGENT_DIR": "/state/agent",
        "XDG_CACHE_HOME": "/state/cache",
        "XDG_CONFIG_HOME": "/home/pi/.config",
        "XDG_DATA_HOME": "/home/pi/.local/share",
        "XDG_STATE_HOME": "/state",
        "TMPDIR": "/tmp",
        "LANG": "C.UTF-8",
        "PI_OLLAMA_WEB_TOOLS": "0",
        "PI_SKIP_VERSION_CHECK": "1",
        "PI_TELEMETRY": "0",
        "PI_DELEGATOR_PI_BINARY": "/tools/bin/pi-child",
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_GLOBAL": "/dev/null",
        "NIX_REMOTE": "local",
        "NIX_STORE_DIR": "/nix/store",
        "NUGET_PACKAGES": "/state/nuget/packages",
        "DOTNET_CLI_HOME": "/state/cache/dotnet",
        "DOTNET_CLI_TELEMETRY_OPTOUT": "1",
        "DOTNET_NOLOGO": "1",
        "SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
        "TERM": os.environ.get("TERM", "xterm-256color"),
    }
    for key, value in env.items():
        argv += ["--setenv", key, value]
    command = (
        ["/bin/python3", cfg["probe"]]
        if probe
        else [cfg["runtime"] + "/bin/pi-internal"]
    )
    argv += ["--chdir", "/project", "--remount-ro", "/", "--", *command, *args]
    return argv


def main():
    parser = argparse.ArgumentParser(
        description="Whole-process sandboxed Pi (no fallback)"
    )
    parser.add_argument("--config", required=True)
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument(
        "--offline",
        action="store_true",
        help="isolate network; models/login unavailable",
    )
    parser.add_argument(
        "--sandbox-test",
        action="store_true",
        help="exercise access-negative acceptance probe",
    )
    parser.add_argument("args", nargs=argparse.REMAINDER)
    options = parser.parse_args()
    cfg = json.loads(Path(options.config).read_text())
    state_root = Path.home() / ".local/state/pi-harness"
    project = validate_project(options.project, state_root, Path.home())
    private_directory(state_root)
    # A global lock protects reconciliation/auth and prevents competing harness writers.
    # It stays in the outer launcher and is never exposed inside the mount namespace.
    lock_fd = os.open(
        state_root / ".launcher.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600
    )
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        os.close(lock_fd)
        raise ValueError("another harness session owns the writer/state lock")
    state = private_directory(checkout_state(state_root, project))
    reject_sockets(state)
    for name in ["agent", "cache", "nuget"]:
        private_directory(state / name)
    templates = json.loads(Path(cfg["template"]).read_text())
    project_settings(state / "agent", templates)
    args = options.args[1:] if options.args[:1] == ["--"] else options.args
    # CLI resource discovery is explicit; no project or mutable ambient addon loading.
    explicit = ["--no-extensions", "--no-skills", "--no-prompt-templates"]
    for extension in cfg["extensions"]:
        explicit += ["--extension", extension]
    for skill in cfg["skills"]:
        explicit += ["--skill", skill]
    if cfg.get("prompt"):
        explicit += ["--append-system-prompt", cfg["prompt"]]
    command = sandbox_argv(
        project,
        state,
        cfg,
        [] if options.sandbox_test else explicit + args,
        offline=options.offline,
        probe=options.sandbox_test,
    )
    # No shell interpolation, no inherited secret-bearing environment or descriptors.
    result = subprocess.run(command, env={}, close_fds=True, check=False)
    os.close(lock_fd)
    return result.returncode


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, json.JSONDecodeError) as error:
        print(f"pi: fail-closed: {error}", file=sys.stderr)
        sys.exit(78)
