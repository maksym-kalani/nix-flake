"""Regression tests for Aigis's served WebUI copy.

Run from the repository root with:
    python3 tests/test_suwayomi_webui_tmpfiles.py

Requires Nix with flakes and systemd-tmpfiles. Cleanup is confined to a
throwaway --root fixture; no live services or system files are changed.
"""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class SuwayomiWebUITmpfilesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = subprocess.run(
            [
                "nix", "eval", "--json",
                ".#nixosConfigurations.aigis.config",
                "--apply",
                "c: { rules = c.systemd.tmpfiles.rules; "
                "triggers = map toString c.systemd.services.suwayomi-server.restartTriggers; "
                "restartIfChanged = c.systemd.services.suwayomi-server.restartIfChanged; "
                'unit = c.systemd.units."suwayomi-server.service".text; }',
            ],
            cwd=REPO,
            check=True,
            capture_output=True,
            text=True,
        )
        cls.config = json.loads(result.stdout)
        cls.webui_rules = [
            rule for rule in cls.config["rules"]
            if len(rule.split()) >= 2
            and rule.split()[1] == "/tmp/Tachidesk"
        ]

    def test_policy_change_restarts_service_to_restore_served_copy(self):
        triggers = [
            Path(path) for path in self.config["triggers"]
            if path.endswith("-suwayomi-webui-tmpfiles.conf")
        ]
        self.assertEqual(len(triggers), 1, "WebUI policy restart trigger is missing")
        trigger = triggers[0]
        self.assertEqual(
            trigger.read_text(), "\n".join(self.webui_rules) + "\n"
        )
        self.assertTrue(self.config["restartIfChanged"])
        # NixOS puts the trigger paths in a generated wrapper file and embeds
        # that wrapper's store path in the unit, not each input path directly.
        self.assertIn("\nX-Restart-Triggers=/nix/store/", self.config["unit"])

    def test_cleanup_preserves_webui_but_cleans_unrelated_files(self):
        with tempfile.TemporaryDirectory(
            prefix="suwayomi-tmpfiles-", dir=os.environ.get("TMPDIR")
        ) as directory:
            root = Path(directory)
            protected = root / "tmp/Tachidesk/webUI-serve/assets/Manga-test.js"
            unrelated = root / "tmp/unrelated-cache/stale.js"
            for path in (protected, unrelated):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("export default {};\n")
            policy = root / "cleanup.conf"
            policy.write_text(
                "d /tmp 1777 - - 0\n" + "\n".join(self.webui_rules) + "\n"
            )
            subprocess.run(
                ["systemd-tmpfiles", f"--root={root}", "--clean", str(policy)],
                check=True,
                capture_output=True,
                text=True,
            )
            self.assertFalse(unrelated.exists(), "control file was not cleaned")
            self.assertTrue(
                protected.exists(), "cleanup deleted a served WebUI module"
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
