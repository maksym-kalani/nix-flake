import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).parents[2] / "pkgs/pi-harness/launcher.py"


class LauncherTests(unittest.TestCase):
    def load(self):
        self.assertTrue(SOURCE.exists(), "sandbox launcher behavior not implemented")
        spec = importlib.util.spec_from_file_location("launcher", SOURCE)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_projection_preserves_auth_sessions_and_user_settings(self):
        module = self.load()
        with tempfile.TemporaryDirectory() as temp:
            state = Path(temp) / "state"
            state.mkdir(mode=0o700)
            (state / "auth.json").write_text('{"test":"not-a-secret"}')
            (state / "settings.json").write_text('{"theme":"dark","deviceId":"keep"}')
            (state / "sessions").mkdir()
            (state / "sessions/existing").write_text("keep")
            module.project_settings(
                state, {"settings.json": {"defaultProvider": "ollama-cloud"}}
            )
            self.assertEqual(
                json.loads((state / "settings.json").read_text()),
                {
                    "theme": "dark",
                    "deviceId": "keep",
                    "defaultProvider": "ollama-cloud",
                },
            )
            self.assertEqual(
                (state / "auth.json").read_text(), '{"test":"not-a-secret"}'
            )
            self.assertEqual((state / "sessions/existing").read_text(), "keep")
            self.assertFalse((state / "settings.json").is_symlink())
            self.assertEqual((state / "settings.json").stat().st_mode & 0o777, 0o600)

    def test_containment_argv_has_only_scoped_writes_and_clean_env(self):
        module = self.load()
        self.assertTrue(hasattr(module, "sandbox_argv"), "containment not implemented")
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            project = root / "project with ; shell chars"
            project.mkdir()
            state = root / "state"
            state.mkdir(mode=0o700)
            cfg = {
                "bwrap": "/tool/bwrap",
                "tools": "/nix/store/tools",
                "runtime": "/nix/store/runtime",
                "template": "/nix/store/template",
            }
            argv = module.sandbox_argv(project, state, cfg, ["--version"], offline=True)
            self.assertEqual(argv[0], "/tool/bwrap")
            for flag in [
                "--unshare-user",
                "--unshare-pid",
                "--unshare-ipc",
                "--unshare-uts",
                "--unshare-net",
                "--disable-userns",
                "--clearenv",
                "--die-with-parent",
                "--new-session",
            ]:
                self.assertIn(flag, argv)
            binds = [argv[i + 1 : i + 3] for i, x in enumerate(argv) if x == "--bind"]
            self.assertEqual(
                binds, [[str(project), "/project"], [str(state), "/state"]]
            )
            self.assertIn("/home/pi", argv)
            self.assertNotIn(str(Path.home()), argv)
            self.assertNotIn("SSH_AUTH_SOCK", argv)
            self.assertNotIn("/run", argv)
            self.assertEqual(argv[-1], "--version")

    def test_rejects_external_git_worktree_and_symlink_roots(self):
        module = self.load()
        self.assertTrue(
            hasattr(module, "validate_project"), "path containment not implemented"
        )
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            project = root / "repo"
            project.mkdir()
            alias = root / "alias"
            alias.symlink_to(project, target_is_directory=True)
            with self.assertRaises(ValueError):
                module.validate_project(alias, root / "state", root / "home")
            (project / ".git").write_text("gitdir: ../outside/worktrees/repo\n")
            with self.assertRaises(ValueError):
                module.validate_project(project, root / "state", root / "home")
            with self.assertRaises(ValueError):
                module.validate_project(root, root / "state", root / "home")

    def test_system_directories_are_not_project_roots(self):
        module = self.load()
        with tempfile.TemporaryDirectory() as temp, self.assertRaises(ValueError):
            module.validate_project(
                Path("/etc"), Path(temp) / "state", Path(temp) / "home"
            )

    def test_state_isolated_per_checkout_and_socket_mounts_rejected(self):
        module = self.load()
        self.assertTrue(
            hasattr(module, "checkout_state"),
            "per-checkout state isolation not implemented",
        )
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            one, two = root / "one", root / "two"
            one.mkdir()
            two.mkdir()
            self.assertNotEqual(
                module.checkout_state(root / "state", one),
                module.checkout_state(root / "state", two),
            )
            import socket

            endpoint = socket.socket(socket.AF_UNIX)
            endpoint.bind(str(one / "docker.sock"))
            try:
                with self.assertRaises(ValueError):
                    module.validate_project(one, root / "state", root / "home")
            finally:
                endpoint.close()

    def test_projection_rejects_symlink_without_reading_external_target(self):
        module = self.load()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            state = root / "state"
            state.mkdir(mode=0o700)
            external = root / "outside"
            external.write_text('{"keep": true}')
            (state / "settings.json").symlink_to(external)
            with self.assertRaises(ValueError):
                module.project_settings(
                    state, {"settings.json": {"defaultProvider": "ollama-cloud"}}
                )
            self.assertEqual(external.read_text(), '{"keep": true}')


if __name__ == "__main__":
    unittest.main()
