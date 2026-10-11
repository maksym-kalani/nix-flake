import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

RUNNER = Path(__file__).parents[2] / "pkgs/pi-harness/check_runner.py"


class CheckRunnerTests(unittest.TestCase):
    def test_dotnet_runner_override_is_executed_as_argv_not_shell(self):
        self.assertTrue(RUNNER.exists(), "project check runner not implemented")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".pi").mkdir()
            (root / ".pi/checks.json").write_text(
                json.dumps(
                    {
                        "testCommand": [
                            shutil.which("sh"),
                            "-c",
                            "printf '%s' \"$1\" > ran",
                            "runner",
                            "literal;no-shell",
                        ]
                    }
                )
            )
            result = subprocess.run(
                [sys.executable, str(RUNNER), "dotnet-test"],
                cwd=root,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((root / "ran").read_text(), "literal;no-shell")

    def test_native_mtp_without_project_command_is_blocked(self):
        self.assertTrue(RUNNER.exists(), "project check runner not implemented")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".pi").mkdir()
            (root / ".pi/checks.json").write_text('{"testRunner":"mtp"}')
            result = subprocess.run(
                [sys.executable, str(RUNNER), "dotnet-test"],
                cwd=root,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 78)
            self.assertIn("testCommand", result.stderr)

    def test_nix_daemon_exception_never_attempts_switch_or_privilege(self):
        self.assertTrue(RUNNER.exists(), "project check runner not implemented")
        result = subprocess.run(
            [sys.executable, str(RUNNER), "nix-eval"],
            env={**os.environ, "PI_CODING_AGENT_DIR": "/state/agent"},
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 78)
        self.assertIn("outside-sandbox", result.stderr)


if __name__ == "__main__":
    unittest.main()
