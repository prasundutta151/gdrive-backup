import importlib.machinery
import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "gdrive-backup"


def load_module(config_path: Path):
    loader = importlib.machinery.SourceFileLoader("gdrive_backup_test", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    with mock.patch.dict(os.environ, {"GDRIVE_BACKUP_CONFIG": str(config_path)}):
        loader.exec_module(module)
    return module


class SetupTests(unittest.TestCase):
    def test_normalize_web_destination(self):
        with tempfile.TemporaryDirectory() as directory:
            module = load_module(Path(directory) / "config.json")
            self.assertEqual(module.normalize_web_destination("Backup"), "gdrive:Backup")
            self.assertEqual(module.normalize_web_destination("work:Docs"), "work:Docs")

    def test_setup_saves_defaults_without_auth_in_test_mode(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            local = root / "Documents"
            local.mkdir()
            config = root / "config.json"
            module = load_module(config)
            result = module.cmd_setup([
                "--local", str(local), "--web", "Test_Backup", "--no-auth",
            ])
            self.assertEqual(result, 0)
            saved = json.loads(config.read_text(encoding="utf-8"))
            self.assertEqual(saved["local"], str(local))
            self.assertEqual(saved["web"], "gdrive:Test_Backup")
            self.assertEqual(saved["remote"], "gdrive")


if __name__ == "__main__":
    unittest.main()
