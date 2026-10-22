"""Tagged builds must never silently fall back to Flutter's debug key."""
import os
from pathlib import Path
import subprocess
import unittest


class AndroidSigningTests(unittest.TestCase):
    def run_gate(self, tagged, keys):
        env = {key: value for key, value in os.environ.items()
               if not key.startswith('DITMESH_ANDROID_')}
        env['GITHUB_REF_TYPE'] = 'tag' if tagged else 'branch'
        for key in keys:
            env[f'DITMESH_ANDROID_{key}'] = 'fixture'
        return subprocess.run(
            ['bash', str(Path(__file__).with_name('require_android_signing.sh'))],
            env=env, capture_output=True, text=True, check=False)

    def test_unsigned_branch_validation_remains_available(self):
        self.assertEqual(self.run_gate(False, []).returncode, 0)

    def test_tag_requires_every_signing_input(self):
        keys = ['KEYSTORE', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD']
        self.assertEqual(self.run_gate(True, keys).returncode, 0)
        for missing in keys:
            with self.subTest(missing=missing):
                result = self.run_gate(True, [key for key in keys if key != missing])
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('release signing', result.stderr)
                self.assertNotIn('fixture', result.stderr)


if __name__ == '__main__':
    unittest.main()
