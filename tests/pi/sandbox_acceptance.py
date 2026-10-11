"""Disposable real-sandbox acceptance; namespace denial is a failure, never a skip."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

launcher = sys.argv[1]
with tempfile.TemporaryDirectory(prefix="pi-sandbox-acceptance-") as temp:
    root = Path(temp)
    project = root / "project with spaces;literal"
    project.mkdir()
    home = root / "host-home"
    home.mkdir(mode=0o700)
    secret = home / "outside-secret"
    secret.write_text("acceptance sentinel, not credentials")
    (project / "outside-link").symlink_to(secret)
    expected = {
        "outside": str(secret),
        "namespaces": {
            name: os.readlink("/proc/self/ns/" + name)
            for name in ["user", "mnt", "pid", "ipc", "uts", "net"]
        },
    }
    (project / "host-namespaces.json").write_text(json.dumps(expected))
    result = subprocess.run(
        [launcher, "--project", str(project), "--offline", "--sandbox-test"],
        env={
            **os.environ,
            "HOME": str(home),
            "SSH_AUTH_SOCK": str(root / "agent.sock"),
            "DOCKER_HOST": "unix:///run/docker.sock",
        },
        check=False,
    )
    if result.returncode:
        print(
            "BLOCKED/FAIL: real sandbox acceptance did not execute successfully; no unsandboxed fallback",
            file=sys.stderr,
        )
        sys.exit(result.returncode)
    assert (project / "acceptance-written").read_text() == "contained"
    assert (project / "child-written").exists()
    assert secret.read_text() == "acceptance sentinel, not credentials"
    print(
        "PASS: outer host sentinel unchanged and contained parent/descendant writes read back"
    )
