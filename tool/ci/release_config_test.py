#!/usr/bin/env python3
"""Regression checks for mismatched versions and incomplete release uploads."""
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

from macos_components import configure_components

TOOLS = Path(__file__).resolve().parent
NATIVE_MANAGER_FIXTURE = (
    "        tox_options_set_dht_announcements_enabled(opts, tox_options_get_dht_announcements_enabled(options));\n"
    "    }\n"
    "    \n"
    "    if (savedata && savedata_length > 0) {\n"
    "        tox_options_set_savedata_type(opts, TOX_SAVEDATA_TYPE_TOX_SAVE);\n"
)


class ReleaseValidationTests(unittest.TestCase):
    def copy_native_group_sources(self, source):
        upstream = TOOLS.parents[1] / "third_party" / "tim2tox"
        for relative in ("source/V2TIMGroupManagerImpl.cpp", "ffi/dart_compat_group.cpp"):
            destination = source / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(upstream / relative, destination)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.spec = self.root / "pubspec.yaml"
        self.spec.write_text("version: 2.3.4+17\n")
        self.env = dict(os.environ, DITMESH_APP_PUBSPEC=str(self.spec))
        self.env.pop("GITHUB_REF_TYPE", None)
        self.env.pop("GITHUB_REF_NAME", None)

    def run_script(self, script, *args, **env):
        return subprocess.run(
            ["bash", str(TOOLS / script), *map(str, args)],
            env=dict(self.env, **env), capture_output=True, text=True,
            check=False,
        )

    def test_tag_must_match_embedded_app_version(self):
        valid = self.run_script("release_version.sh", GITHUB_REF_TYPE="tag",
                                GITHUB_REF_NAME="v2.3.4")
        self.assertEqual(valid.returncode, 0, valid.stderr)
        self.assertEqual(valid.stdout.strip(), "2.3.4")
        build = self.run_script("release_version.sh", "--build-number")
        self.assertEqual(build.returncode, 0, build.stderr)
        self.assertEqual(build.stdout.strip(), "17")
        for tag in ("v9.9.9", "v2.3.4-beta", "2.3.4"):
            with self.subTest(tag=tag):
                invalid = self.run_script("release_version.sh",
                                          GITHUB_REF_TYPE="tag",
                                          GITHUB_REF_NAME=tag)
                self.assertNotEqual(invalid.returncode, 0)

    def test_missing_build_number_is_rejected(self):
        self.spec.write_text("version: 2.3.4\n")
        self.assertNotEqual(self.run_script("release_version.sh").returncode, 0)

    def test_apple_plugin_cleanup_recovers_from_stale_compiler_cache(self):
        cmake = shutil.which("cmake")
        self.assertIsNotNone(cmake, "CMake is required for the native-cache regression")
        package = self.root / "pub-cache" / "hosted" / "pub.dev" / "flutter_soloud-4.1.7"
        for platform in ("macos", "ios"):
            with self.subTest(platform=platform):
                source = package / platform
                source.mkdir(parents=True)
                (source / "CMakeLists.txt").write_text(
                    "cmake_minimum_required(VERSION 3.16)\nproject(plugin_cache_fixture C)\n"
                )
                output = source / "cmake_build" / "fixture"

                def configure():
                    return subprocess.run([cmake, "-S", str(source), "-B", str(output)],
                                          capture_output=True, text=True, check=False)

                initial = configure()
                self.assertEqual(initial.returncode, 0, initial.stderr)
                cache = output / "CMakeCache.txt"
                cached = re.sub(r"^CMAKE_C_COMPILER:[^=]+=.*$",
                                "CMAKE_C_COMPILER:FILEPATH=/removed/Xcode.app/usr/bin/clang",
                                cache.read_text(), flags=re.MULTILINE)
                cache.write_text(cached)
                stale = configure()
                self.assertNotEqual(stale.returncode, 0)
                self.assertIn("not a full path to an existing compiler tool", stale.stderr)
                preserved = package / "other-source.txt"
                preserved.write_text("keep package sources")
                result = self.run_script("clean_apple_plugin_cache.sh", platform,
                                         PUB_CACHE=str(self.root / "pub-cache"))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(output.exists())
                self.assertTrue(preserved.exists())
                self.assertTrue((source / "CMakeLists.txt").exists())
                recovered = configure()
                self.assertEqual(recovered.returncode, 0, recovered.stderr)
        self.assertTrue((package / "macos" / "cmake_build").exists(),
                        "Cleaning iOS must preserve the other platform's outputs")

    def test_complete_set_creates_verifiable_checksums(self):
        suffixes = (
            "linux-x86_64.deb", "linux-x86_64.rpm", "linux-x86_64.tar.gz",
            "windows-x64.msi", "windows-x64.zip", "macos-arm64.pkg",
            "macos-arm64.zip", "macos-x86_64.pkg", "macos-x86_64.zip",
            "android.apk", "android.aab", "ios-unsigned.ipa",
        )
        dist = self.root / "dist"
        dist.mkdir()
        assets = [dist / f"ditmesh-2.3.4-{suffix}" for suffix in suffixes]
        for asset in assets:
            asset.write_bytes(asset.name.encode())
        result = self.run_script("verify_release_assets.sh", dist, "v2.3.4")
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = (dist / "SHA256SUMS").read_text().splitlines()
        self.assertEqual(len(manifest), 12)
        for line in manifest:
            digest, name = line.split("  ", 1)
            self.assertEqual(digest, hashlib.sha256((dist / name).read_bytes()).hexdigest())
        assets[0].unlink()
        self.assertNotEqual(self.run_script("verify_release_assets.sh", dist,
                                           "v2.3.4").returncode, 0)
        assets[0].write_bytes(b"restored")
        (dist / "unreviewed.zip").write_bytes(b"unexpected")
        self.assertNotEqual(self.run_script("verify_release_assets.sh", dist,
                                           "v2.3.4").returncode, 0)

    def test_installer_cannot_relocate_into_another_app(self):
        child = {"RootRelativeBundlePath": "DitMesh.app/Contents/Frameworks/common.framework",
                 "ChildBundles": [{"RootRelativeBundlePath": "DitMesh.app/Contents/Frameworks/common.framework/privacy.bundle"}]}
        entries = [{"RootRelativeBundlePath": child["RootRelativeBundlePath"]},
                   {"RootRelativeBundlePath": "DitMesh.app",
                    "BundleIsRelocatable": True, "ChildBundles": [child]}]
        result = configure_components(entries)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["RootRelativeBundlePath"], "DitMesh.app")
        self.assertTrue(result[0]["BundleHasStrictIdentifier"])
        self.assertFalse(result[0]["BundleIsRelocatable"])
        self.assertFalse(result[0]["ChildBundles"][0]["BundleIsRelocatable"])
        self.assertFalse(result[0]["ChildBundles"][0]["ChildBundles"][0]["BundleIsRelocatable"])
        self.assertTrue(entries[1]["BundleIsRelocatable"])
        with self.assertRaises(ValueError):
            configure_components([])

    def test_ios_download_failure_stops_before_native_configuration(self):
        # iOS calls nested functions through command substitutions, where bash
        # disables errexit. Failed downloads must still stop the entire slice.
        scripts = self.root / "tool" / "ci"
        scripts.mkdir(parents=True)
        for script in ("build_tim2tox.sh", "common.sh", "prepare_native_source.py"):
            shutil.copyfile(TOOLS / script, scripts / script)
        shutil.copytree(TOOLS / "tim2tox-overlays", scripts / "tim2tox-overlays")
        ffi = self.root / "third_party" / "tim2tox" / "ffi"
        ffi.mkdir(parents=True)
        (ffi / "CMakeLists.txt").write_text("# Unused fixture\n")
        toxcore = ffi.parent / "third_party" / "c-toxcore"
        toxcore.mkdir(parents=True)
        (toxcore / "CMakeLists.txt").write_text("# Unused fixture\n")
        source = ffi.parent / "source"
        source.mkdir()
        (source / "ToxManager.cpp").write_text(NATIVE_MANAGER_FIXTURE)
        self.copy_native_group_sources(ffi.parent)
        flutter = self.root / "flutter"
        headers = flutter / "bin" / "cache" / "dart-sdk" / "include"
        headers.mkdir(parents=True)
        (headers / "dart_api_dl.h").touch()
        commands = self.root / "commands"
        commands.mkdir()
        marker = self.root / "configured"
        stubs = {
            "curl": "exit 7\n",
            "xcrun": 'case "$*" in *--show-sdk-path*) echo /mock-sdk ;; *) echo /mock-clang ;; esac\n',
            "cmake": f'touch "{marker}"\nexit 1\n',
            "lipo": "exit 1\n",
            "install_name_tool": "exit 1\n",
        }
        for name, body in stubs.items():
            command = commands / name
            command.write_text("#!/bin/sh\n" + body)
            command.chmod(0o755)
        result = subprocess.run(
            ["bash", str(scripts / "build_tim2tox.sh"), "--target",
             "ios-device", "--no-stage-app"],
            env=dict(self.env, RUNNER_OS="macOS", FLUTTER_ROOT=str(flutter),
                     DITMESH_NATIVE_BUILD_ROOT=str(self.root / "native"),
                     PATH=f"{commands}{os.pathsep}{os.environ['PATH']}"),
            capture_output=True, text=True, check=False, timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Failed to download", result.stderr)
        self.assertIn("arm64 slice failed", result.stderr)
        self.assertFalse(marker.exists(), result.stderr)
        self.assertFalse(list((self.root / "native").rglob("*.part.*")))

    def test_native_overlay_preserves_upstream_and_rejects_source_drift(self):
        source = self.root / "tim2tox"
        manager = source / "source" / "ToxManager.cpp"
        manager.parent.mkdir(parents=True)
        original = NATIVE_MANAGER_FIXTURE
        manager.write_text(original)
        self.copy_native_group_sources(source)
        (source / ".git").write_text("gitdir: /unused/upstream\n")
        destination = self.root / "staged"

        def stage():
            return subprocess.run(
                ["python3", str(TOOLS / "prepare_native_source.py"),
                 str(source), str(destination)],
                capture_output=True, text=True, check=False,
            )

        result = stage()
        self.assertEqual(result.returncode, 0, result.stderr)
        staged = destination / "source" / "ToxManager.cpp"
        self.assertIn("tox_options_set_experimental_groups_persistence(opts, true)",
                      staged.read_text())
        for overlapping in (source, source / "nested", source.parent):
            overlap = subprocess.run(
                ["python3", str(TOOLS / "prepare_native_source.py"),
                 str(source), str(overlapping)],
                capture_output=True, text=True, check=False,
            )
            self.assertNotEqual(overlap.returncode, 0)
            self.assertIn("upstream", overlap.stderr.lower())
        self.assertTrue(manager.exists())
        self.assertEqual(manager.read_text(), original)
        self.assertFalse((destination / ".git").exists())
        modified = staged.stat().st_mtime_ns
        self.assertEqual(stage().returncode, 0)
        self.assertEqual(staged.stat().st_mtime_ns, modified)
        manager.write_text("// Upstream initialization changed\n")
        rejected = stage()
        self.assertNotEqual(rejected.returncode, 0)
        self.assertIn("patch", rejected.stderr.lower())
        self.assertIn("tox_options_set_experimental_groups_persistence(opts, true)",
                      staged.read_text())


if __name__ == "__main__":
    unittest.main()
