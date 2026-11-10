import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "aigis-changed.sh"
EXPRESSION = ROOT / "scripts" / "aigis-fingerprint.nix"
UNCHANGED = {
    "system": "/nix/store/same-system.drv",
    "test": "/nix/store/same-vm.drv",
}


class AigisChangedTests(unittest.TestCase):
    def compare(self, **overrides):
        with tempfile.TemporaryDirectory() as directory:
            nix = Path(directory) / "nix"
            nix.write_text(
                f"#!{sys.executable}\n"
                "import os, sys\n"
                "from pathlib import Path\n"
                "assert sys.argv[1:5] == ['eval', '--json', '--no-update-lock-file', '--file']\n"
                f"assert Path(sys.argv[5]) == Path({str(EXPRESSION)!r})\n"
                "ref = os.environ['AIGIS_FLAKE_REF'].upper()\n"
                "sys.stdout.write(os.environ[ref])\n"
                "sys.exit(int(os.environ.get(ref + '_EXIT', '0')))\n"
            )
            nix.chmod(0o755)
            env = {
                **os.environ,
                "PATH": f"{directory}:{os.environ['PATH']}",
                "BASE": json.dumps(UNCHANGED),
                "CANDIDATE": json.dumps(UNCHANGED),
                **overrides,
            }
            return subprocess.run(
                ["bash", str(SCRIPT), "base", "candidate"],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )

    def test_unchanged_derivations_skip_vm(self):
        result = self.compare()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "false")

    def test_changed_system_requires_vm(self):
        result = self.compare(CANDIDATE=json.dumps({**UNCHANGED, "system": "/nix/store/changed-system.drv"}))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "true")

    def test_changed_test_requires_vm(self):
        result = self.compare(CANDIDATE=json.dumps({**UNCHANGED, "test": "/nix/store/changed-vm.drv"}))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "true")

    def test_base_eval_failure_is_not_a_skip(self):
        result = self.compare(BASE_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_candidate_eval_failure_is_not_a_skip(self):
        result = self.compare(CANDIDATE_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_workflow_uses_derivation_gate(self):
        workflow = (ROOT / "workflows" / "ci.yml").read_text()
        self.assertNotIn("dorny/paths-filter", workflow)
        self.assertIn("if: needs.eval.outputs.aigis_changed == 'true'", workflow)
        self.assertIn("aigis_changed: ${{ steps.aigis.outputs.changed }}", workflow)
        self.assertIn("fetch-depth: 0", workflow)
        self.assertIn("github.event.pull_request.base.sha", workflow)
        self.assertIn("nix shell --inputs-from . nixpkgs#python3 -c python3 -B -m unittest", workflow)

    def test_empty_evaluation_is_not_a_skip(self):
        result = self.compare(BASE="", CANDIDATE="")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
