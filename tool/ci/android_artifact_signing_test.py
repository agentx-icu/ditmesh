"""Real JAR integrity regressions; Android self-signed keys are expected."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

from android_artifact_signing import check_aab, check_apk, check_identity, check_reports, find_apksigner


@unittest.skipUnless(shutil.which('jarsigner') and shutil.which('keytool'), 'JDK required')
class JarIntegrityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmp.name)
        cls.key = cls.root / 'fixture.p12'
        subprocess.run(['keytool', '-genkeypair', '-alias', 'fixture', '-keystore', str(cls.key),
                        '-storepass', 'fixture-password', '-keyalg', 'RSA', '-keysize', '2048',
                        '-validity', '30', '-dname', 'CN=Release fixture', '-noprompt'],
                       capture_output=True, check=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def signed(self):
        path = self.root / 'app.aab'
        with zipfile.ZipFile(path, 'w') as stream:
            stream.writestr('BundleConfig.pb', b'fixture bundle config')
            stream.writestr('base/manifest/AndroidManifest.xml', b'fixture payload')
        subprocess.run(['jarsigner', '-keystore', str(self.key), '-storepass',
                        'fixture-password', str(path), 'fixture'], capture_output=True, check=True)
        return path

    def test_valid_self_signed_android_key_is_accepted(self):
        report = check_aab(self.signed())
        self.assertIn('SHA256:', report)

    def test_unsigned_extra_entry_is_rejected(self):
        path = self.signed()
        with zipfile.ZipFile(path, 'a') as stream:
            stream.writestr('base/unsigned.txt', b'not authenticated')
        with self.assertRaisesRegex(ValueError, 'integrity'):
            check_aab(path)

    def test_tampered_signed_entry_is_rejected(self):
        path = self.signed()
        with zipfile.ZipFile(path) as stream:
            entries = {name: stream.read(name) for name in stream.namelist()}
        entries['base/manifest/AndroidManifest.xml'] = b'tampered'
        with zipfile.ZipFile(path, 'w') as stream:
            for name, data in entries.items():
                stream.writestr(name, data)
        with self.assertRaisesRegex(ValueError, 'integrity'):
            check_aab(path)

    def test_real_apk_signature_matches_aab_and_tampering_fails(self):
        sdk = os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME')
        if not sdk:
            self.skipTest('Android SDK required for actual APK fixture')
        signer = Path(find_apksigner())
        aapt2 = signer.with_name('aapt2')
        platforms = list((Path(sdk) / 'platforms').glob('*/android.jar'))
        if not aapt2.is_file() or not platforms:
            self.skipTest('aapt2 and platform android.jar required')
        manifest = self.root / 'AndroidManifest.xml'
        manifest.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
            package="icu.agentx.ditmesh" android:versionCode="1" android:versionName="1.0">
            <uses-sdk android:minSdkVersion="24"/>
            <application android:hasCode="false"/></manifest>''')
        apk = self.root / 'fixture.apk'
        subprocess.run([str(aapt2), 'link', '-o', str(apk), '--manifest', str(manifest),
                        '-I', str(sorted(platforms)[-1])], capture_output=True, check=True)
        subprocess.run([str(signer), 'sign', '--ks', str(self.key), '--ks-key-alias', 'fixture',
                        '--ks-pass', 'pass:fixture-password', str(apk)], capture_output=True, check=True)
        apk_report, aab_report = check_apk(apk), check_aab(self.signed())
        expected = check_reports(apk_report, aab_report, False, '')
        self.assertEqual(check_reports(apk_report, aab_report, True, expected), expected)
        result = subprocess.run([sys.executable, str(Path(__file__).with_name('android_artifact_signing.py')),
                                 str(apk), str(self.root / 'app.aab'), '--distribution',
                                 '--version', '1.0', '--build-number', '1'],
                                env={**os.environ, 'DITMESH_ANDROID_CERT_SHA256': expected},
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        with self.assertRaisesRegex(ValueError, 'match'):
            check_reports(apk_report, aab_report, True, '12' * 32)
        with zipfile.ZipFile(apk, 'a') as stream:
            stream.writestr('assets/unsigned.txt', b'post-sign modification')
        with self.assertRaisesRegex(ValueError, 'integrity'):
            check_apk(apk)


class SigningIdentityTests(unittest.TestCase):
    fingerprint = 'ab' * 32

    def reports(self, debug=False):
        owner = 'CN=Android Debug' if debug else 'CN=Release'
        return (f'Signer #1 certificate DN: {owner}\nSigner #1 certificate SHA-256 digest: {self.fingerprint}',
                f'Owner: {owner}\nSHA256: {self.fingerprint}')

    def test_expected_identity_required_for_distribution(self):
        apk, aab = self.reports()
        self.assertEqual(check_reports(apk, aab, True, self.fingerprint), self.fingerprint)
        for expected in ('', '12' * 32, 'bad-value'):
            with self.subTest(expected=expected), self.assertRaises(ValueError):
                check_reports(apk, aab, True, expected)

    def test_debug_only_allowed_in_validation_and_mismatches_always_fail(self):
        apk, aab = self.reports(debug=True)
        self.assertEqual(check_reports(apk, aab, False, ''), self.fingerprint)
        with self.assertRaisesRegex(ValueError, 'debug'):
            check_reports(apk, aab, True, self.fingerprint)
        with self.assertRaisesRegex(ValueError, 'match'):
            check_reports(apk, aab.replace(self.fingerprint, '12' * 32), False, '')

    def test_stale_version_wrong_app_id_and_debuggable_manifest_are_rejected(self):
        badging = "package: name='icu.agentx.ditmesh' versionCode='2' versionName='1.1.0'"
        self.assertEqual(check_identity(badging, '1.1.0', '2', True)['build'], '2')
        for invalid in (badging.replace('icu.agentx.ditmesh', 'other.app'),
                        badging.replace("versionCode='2'", "versionCode='1'"),
                        badging.replace("versionName='1.1.0'", "versionName='1.0.0'"),
                        badging + '\napplication-debuggable'):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                check_identity(invalid, '1.1.0', '2', True)


if __name__ == '__main__':
    unittest.main()
