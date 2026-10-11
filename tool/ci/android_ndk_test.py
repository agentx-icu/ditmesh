#!/usr/bin/env python3
"""Regression checks for install_android_ndk.sh against a fake SDK/Flutter."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parent
PIN = "28.2.13676358"


def write_exec(path, body):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("#!/usr/bin/env bash\n" + body)
    path.chmod(0o755)


class InstallAndroidNdkTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.sdk = self.root / "sdk"
        self.sdk.mkdir()
        self.bin = self.root / "bin"
        # `sleep` is stubbed so the retry back-off does not slow the test.
        write_exec(self.bin / "sleep", "exit 0\n")
        self.flutter = self.root / "flutter"
        self.flutter_ndk(PIN)
        self.github_env = self.root / "github_env"
        self.github_env.write_text("")
        self.attempts = self.root / "attempts"

    def flutter_ndk(self, version):
        write_exec(self.flutter / "bin" / "flutter", "exit 0\n")
        ext = (self.flutter / "packages" / "flutter_tools" / "gradle" / "src"
               / "main" / "kotlin" / "FlutterExtension.kt")
        ext.parent.mkdir(parents=True, exist_ok=True)
        ext.write_text(f'    val ndkVersion: String = "{version}"\n')

    def install_ndk(self, revision=PIN):
        ndk = self.sdk / "ndk" / PIN
        (ndk / "build" / "cmake").mkdir(parents=True, exist_ok=True)
        (ndk / "build" / "cmake" / "android.toolchain.cmake").write_text("")
        (ndk / "source.properties").write_text(f"Pkg.Revision = {revision}\n")

    def fake_sdkmanager(self, fail_attempts):
        # Fails the first `fail_attempts` runs, then installs the pinned NDK.
        write_exec(
            self.sdk / "cmdline-tools" / "latest" / "bin" / "sdkmanager",
            f'n=$(( $(cat "{self.attempts}" 2>/dev/null || echo 0) + 1 ))\n'
            f'echo "$n" > "{self.attempts}"\n'
            f'[ "$*" = "--sdk_root={self.sdk} --install ndk;{PIN}" ] || exit 9\n'
            f'[ "$n" -gt {fail_attempts} ] || exit 1\n'
            f'ndk="{self.sdk}/ndk/{PIN}"\n'
            f'mkdir -p "$ndk/build/cmake"\n'
            f'touch "$ndk/build/cmake/android.toolchain.cmake"\n'
            f'echo "Pkg.Revision = {PIN}" > "$ndk/source.properties"\n',
        )

    def run_script(self, flutter=True, **env):
        path = [str(self.bin)]
        if flutter:
            path.append(str(self.flutter / "bin"))
        path += ["/usr/bin", "/bin"]
        environ = {
            "PATH": os.pathsep.join(path),
            "HOME": str(self.root),
            "ANDROID_HOME": str(self.sdk),
            "ANDROID_NDK_VERSION": PIN,
            "GITHUB_ENV": str(self.github_env),
        }
        environ.update(env)
        return subprocess.run(
            ["bash", str(TOOLS / "install_android_ndk.sh")], env=environ,
            capture_output=True, text=True, check=False,
        )

    def exported(self):
        ndk = self.sdk / "ndk" / PIN
        return f"ANDROID_NDK_HOME={ndk}\nANDROID_NDK_ROOT={ndk}\n"

    def test_installed_pin_is_exported_without_sdkmanager(self):
        self.install_ndk()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.github_env.read_text(), self.exported())

    def test_pin_must_match_flutters_ndk(self):
        self.install_ndk()
        self.flutter_ndk("27.0.12077973")
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Flutter's ndkVersion is 27.0.12077973", result.stderr)
        self.assertEqual(self.github_env.read_text(), "")

    def test_missing_flutter_only_warns(self):
        self.install_ndk()
        result = self.run_script(flutter=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("flutter not on PATH", result.stderr)
        self.assertEqual(self.github_env.read_text(), self.exported())

    def test_failed_install_is_retried(self):
        self.fake_sdkmanager(fail_attempts=2)
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.attempts.read_text().strip(), "3")
        self.assertEqual(self.github_env.read_text(), self.exported())

    def test_three_failed_installs_abort(self):
        self.fake_sdkmanager(fail_attempts=3)
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.attempts.read_text().strip(), "3")
        self.assertIn(f"could not install ndk;{PIN}", result.stderr)
        self.assertEqual(self.github_env.read_text(), "")

    def test_wrong_installed_revision_is_rejected(self):
        self.install_ndk(revision="28.0.1")
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Pkg.Revision '28.0.1'", result.stderr)
        self.assertEqual(self.github_env.read_text(), "")

    def test_missing_sdk_is_rejected(self):
        result = self.run_script(ANDROID_HOME=str(self.root / "none"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ANDROID_HOME / ANDROID_SDK_ROOT", result.stderr)


if __name__ == "__main__":
    unittest.main()
