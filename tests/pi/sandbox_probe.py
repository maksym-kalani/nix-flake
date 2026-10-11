"""Acceptance probe: must run inside the actual launcher, never on the host."""

import os
import subprocess
from pathlib import Path

assert os.environ["HOME"] == "/home/pi"
import json

expected = json.loads(Path("/project/host-namespaces.json").read_text())
for name, identity in expected["namespaces"].items():
    assert os.readlink("/proc/self/ns/" + name) != identity, name + " was not isolated"
assert not Path(expected["outside"]).exists()
assert not Path("/project/outside-link").exists()
assert os.environ["PI_OLLAMA_WEB_TOOLS"] == "0"
for variable in [
    "SSH_AUTH_SOCK",
    "GPG_AGENT_INFO",
    "DBUS_SESSION_BUS_ADDRESS",
    "DOCKER_HOST",
    "ANTHROPIC_API_KEY",
    "OPENAI_API_KEY",
    "LD_PRELOAD",
    "NODE_OPTIONS",
]:
    assert variable not in os.environ, variable
for path in [
    "/home/maksym",
    "/root",
    "/run/docker.sock",
    "/var/run/docker.sock",
    "/run/user",
    "/nix/var/nix/daemon-socket/socket",
    "/etc/shadow",
    "/host",
]:
    assert not Path(path).exists(), path
for path in [
    "/etc/forbidden",
    "/nix/store/forbidden",
    "/home/pi/forbidden",
    "/forbidden",
]:
    try:
        Path(path).write_text("escape")
    except OSError:
        pass
    else:
        raise AssertionError("unexpected host/root write: " + path)
for path in [
    "/project/acceptance-written",
    "/state/cache/acceptance-written",
    "/state/agent/acceptance-written",
]:
    Path(path).write_text("contained")
assert Path("/proc/1").exists()
assert not Path("/proc/1/root/home/maksym").exists()
status = Path("/proc/self/status").read_text()
assert "CapEff:\t0000000000000000" in status
assert "NoNewPrivs:\t1" in status
child = subprocess.run(
    [
        "/bin/bash",
        "-c",
        "test ! -e /run/docker.sock && test ! -e /home/maksym && touch /project/child-written",
    ],
    check=False,
)
assert child.returncode == 0
print(
    "PASS: real namespaces, minimal HOME/env, no host sockets/home/proc escape; scoped parent+child writes"
)
