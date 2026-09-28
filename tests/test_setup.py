"""Offline installer regressions. No sudo, package operations or network access."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="velum-setup-test-")
        self.root = Path(self.temp.name)
        self.src = self.root / "source"
        self.dest = self.root / "destination"
        self.src.write_text("new content\n")
        self.state = self.root / "state"
        self.state.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def preflight(self, replace=False, install=False):
        script = '''
component=fish
source "$1/scripts/lib/setup.sh"
state_dir="$2/state"
dry_run=true
replace="$3"
add_file "$2/source" "$2/destination"
preflight
if [[ "$4" == yes ]]; then install_files; fi
'''
        return subprocess.run(["bash", "-c", script, "test", str(REPO), str(self.root),
                               str(replace).lower(), "yes" if install else "no"],
                              capture_output=True, text=True)

    def test_new_install_dry_run_has_no_writes(self):
        result = self.preflight(install=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.dest.exists())
        self.assertEqual(list(self.state.iterdir()), [])
        self.assertIn("install -D", result.stdout)

    def test_unmanaged_file_refused(self):
        self.dest.write_text("personal settings\n")
        result = self.preflight()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--replace", result.stderr)
        self.assertEqual(self.dest.read_text(), "personal settings\n")

    def test_replace_plans_backup_without_writing(self):
        self.dest.write_text("old\n")
        result = self.preflight(replace=True, install=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("cp --parents -a", result.stdout)
        self.assertEqual(self.dest.read_text(), "old\n")

    def test_identical_files_are_not_reinstalled(self):
        self.dest.write_bytes(self.src.read_bytes())
        result = self.preflight(install=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("install -D", result.stdout)

    def test_managed_update_then_local_edit_detection(self):
        self.dest.write_text("previous version\n")
        digest = hashlib.sha256(self.dest.read_bytes()).hexdigest()
        (self.state / "fish.sha256").write_text(f"{digest}  {self.dest}\n")
        self.assertEqual(self.preflight().returncode, 0)
        self.dest.write_text("locally edited\n")
        self.assertNotEqual(self.preflight().returncode, 0)

    def test_symlinks_refused_even_with_replace(self):
        self.dest.symlink_to(self.src)
        self.assertNotEqual(self.preflight(replace=True).returncode, 0)

    def test_cli_rejects_bad_arguments_without_sudo(self):
        for name in ("setup-fish", "setup-nvim"):
            for args in (["--unknown"], ["--user"]):
                p = subprocess.run(["bash", str(REPO / "scripts" / name), *args], capture_output=True)
                self.assertNotEqual(p.returncode, 0)

    def test_configs_contain_no_personal_or_external_shell_paths(self):
        for path in (REPO / "config").rglob("*"):
            if not path.is_file():
                continue
            data = path.read_text()
            for forbidden in ("/home/jess", "illogical-impulse", "qs -c ii", "quickshell/user/generated", "end-4", "caelestia"):
                self.assertNotIn(forbidden, data, str(path))
        with (REPO / "config/starship.toml").open("rb") as f:
            tomllib.load(f)
        json.loads((REPO / "config/nvim/lazy-lock.json").read_text())


if __name__ == "__main__":
    unittest.main(verbosity=2)
