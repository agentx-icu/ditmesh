"""Exercise final sealing with real codesign, including post-sign mutation."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest

from macos_signing import seal, verify


@unittest.skipUnless(sys.platform == 'darwin' and shutil.which('clang'), 'macOS tools required')
class MacSigningTests(unittest.TestCase):
    def test_final_entitlements_and_resource_seal(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            app = root / 'Fixture.app'
            executable = app / 'Contents/MacOS/Fixture'
            executable.parent.mkdir(parents=True)
            resources = app / 'Contents/Resources'
            resources.mkdir()
            source = root / 'fixture.c'
            source.write_text('int main(void) { return 0; }\n')
            subprocess.run(['clang', str(source), '-o', str(executable)], check=True)
            (app / 'Contents/Info.plist').write_bytes(plistlib.dumps({
                'CFBundleIdentifier': 'icu.agentx.signing-fixture',
                'CFBundleExecutable': 'Fixture', 'CFBundlePackageType': 'APPL'}))
            entitlement = root / 'release.plist'
            entitlement.write_bytes(plistlib.dumps({'com.apple.security.get-task-allow': True}))
            subprocess.run(['codesign', '--force', '--sign', '-', '--entitlements',
                            str(entitlement), str(app)], capture_output=True, check=True)
            with self.assertRaisesRegex(ValueError, 'get-task-allow'):
                verify(app)
            entitlement.write_bytes(plistlib.dumps({}))
            seal(app, entitlement)
            self.assertGreater(verify(app)['signed_code'], 0)
            (resources / 'after-sign.txt').write_text('last mutation')
            with self.assertRaisesRegex(ValueError, 'signature'):
                verify(app)
            seal(app, entitlement)
            self.assertGreater(verify(app)['signed_code'], 0)


if __name__ == '__main__':
    unittest.main()
