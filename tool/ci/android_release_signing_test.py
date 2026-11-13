"""Tagged builds must never silently fall back to Flutter's debug key."""
import os
from pathlib import Path
import subprocess
import unittest


class AndroidSigningTests(unittest.TestCase):
    def run_gate(self, tagged, keys, *, distribution=False):
        env = {key: value for key, value in os.environ.items()
               if not key.startswith('DITMESH_ANDROID_')}
        env['GITHUB_REF_TYPE'] = 'tag' if tagged else 'branch'
        env['DITMESH_DISTRIBUTION'] = '1' if distribution else '0'
        for key in keys:
            env[f'DITMESH_ANDROID_{key}'] = 'fixture'
        return subprocess.run(
            ['bash', str(Path(__file__).with_name('require_android_signing.sh'))],
            env=env, capture_output=True, text=True, check=False)

    def test_unsigned_branch_validation_remains_available(self):
        self.assertEqual(self.run_gate(False, []).returncode, 0)

    def test_tag_requires_every_signing_input(self):
        keys = ['KEYSTORE', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD', 'CERT_SHA256']
        self.assertEqual(self.run_gate(True, keys).returncode, 0)
        for missing in keys:
            with self.subTest(missing=missing):
                result = self.run_gate(True, [key for key in keys if key != missing])
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('release signing', result.stderr)
                self.assertNotIn('fixture', result.stderr)

    def test_distribution_requires_expected_certificate_on_a_branch(self):
        signing_keys = ['KEYSTORE', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD']
        result = self.run_gate(False, signing_keys, distribution=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('DITMESH_ANDROID_CERT_SHA256', result.stderr)
        self.assertEqual(self.run_gate(
            False, signing_keys + ['CERT_SHA256'], distribution=True).returncode, 0)


if __name__ == '__main__':
    unittest.main()
