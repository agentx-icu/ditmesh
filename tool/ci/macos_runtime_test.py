#!/usr/bin/env python3
"""Bundle compatibility regressions using actual otool command layouts."""
import plistlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from macos_runtime import check_bundle, inspect_binary, parse_versions


def build_version(version, platform="1"):
    return ("Load command 2\n      cmd LC_BUILD_VERSION\n  cmdsize 32\n"
            f" platform {platform}\n    minos {version}\n      sdk 15.5\n"
            "   ntools 1\n     tool 3\n  version 1115.7.3\n")


class MacRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / "Example.app"
        self.info = self.app / "Contents/Info.plist"
        self.info.parent.mkdir(parents=True)
        self.set_floor("13.0")
        self.binary = self.app / "Contents/MacOS/Example"
        self.binary.parent.mkdir()
        self.binary.write_bytes(b"\xcf\xfa\xed\xfe" + b"fixture")
        self.outputs = {self.binary.resolve(): build_version("13.0")}

    def set_floor(self, version):
        info = {} if version is None else {"LSMinimumSystemVersion": version}
        self.info.write_bytes(plistlib.dumps(info))

    def inspect(self, path):
        return self.outputs[path]

    def test_dependency_above_declared_floor_is_rejected(self):
        self.set_floor("10.15")
        plugin = self.app / "Contents/Frameworks/objective_c.framework/objective_c"
        plugin.parent.mkdir(parents=True)
        plugin.write_bytes(b"\xcf\xfa\xed\xfe" + b"fixture")
        self.outputs[self.binary.resolve()] = build_version("10.15")
        self.outputs[plugin.resolve()] = build_version("13.0")
        with self.assertRaisesRegex(ValueError, "objective_c.*13.0.*10.15"):
            check_bundle(self.app, self.inspect)
        self.set_floor("13.0")
        self.assertEqual(len(check_bundle(self.app, self.inspect)["binaries"]), 2)

    def test_all_universal_slices_are_checked(self):
        text = "Example (architecture arm64):\n" + build_version("12.0")
        text += "Example (architecture x86_64):\n" + build_version("14.0")
        self.outputs[self.binary.resolve()] = text
        self.assertEqual(parse_versions(text), [(12, 0, 0), (14, 0, 0)])
        with self.assertRaisesRegex(ValueError, "14.0.*13.0"):
            check_bundle(self.app, self.inspect)
        missing = "Example (architecture arm64):\nLoad command 0\n cmd LC_UUID\n"
        missing += "Example (architecture x86_64):\n" + build_version("13.0")
        with self.assertRaisesRegex(ValueError, "no macOS"):
            parse_versions(missing)

    def test_inspector_requests_all_architectures_from_otool(self):
        with patch("macos_runtime.subprocess.run") as run:
            run.return_value.returncode = 0
            run.return_value.stdout = build_version("13.0")
            inspect_binary(self.binary)
            self.assertEqual(run.call_args.args[0],
                             ["otool", "-arch", "all", "-l", str(self.binary)])

    def test_legacy_minimum_command_and_later_tool_version(self):
        text = ("Load command 0\n cmd LC_VERSION_MIN_MACOSX\n cmdsize 16\n"
                " version 10.15\n sdk 14.3\nLoad command 1\n cmd LC_UUID\n")
        self.assertEqual(parse_versions(text), [(10, 15, 0)])
        self.assertEqual(parse_versions(build_version("13.0")), [(13, 0, 0)])

    def test_wrong_platform_missing_and_malformed_commands_are_rejected(self):
        for text in [build_version("13.0", "2"), "Load command 0\n cmd LC_UUID\n",
                     build_version("invalid"), "cmd LC_BUILD_VERSION\n platform 1\n"]:
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse_versions(text)

    def test_missing_or_invalid_app_metadata_is_rejected(self):
        for value in [None, "$(MACOSX_DEPLOYMENT_TARGET)", "13.bad"]:
            self.set_floor(value)
            with self.subTest(value=value), self.assertRaises(ValueError):
                check_bundle(self.app, self.inspect)

    def test_framework_symlinks_are_deduplicated_and_external_links_rejected(self):
        alias = self.binary.parent / "alias"
        alias.symlink_to(self.binary.name)
        self.assertEqual(len(check_bundle(self.app, self.inspect)["binaries"]), 1)
        outside = self.root / "external"
        outside.write_bytes(self.binary.read_bytes())
        alias.unlink()
        alias.symlink_to(outside)
        with self.assertRaisesRegex(ValueError, "outside"):
            check_bundle(self.app, self.inspect)

    def test_non_native_resources_are_ignored_but_empty_bundle_is_rejected(self):
        (self.binary.parent / "resource.txt").write_text("ordinary resource")
        self.assertEqual(len(check_bundle(self.app, self.inspect)["binaries"]), 1)
        self.binary.unlink()
        with self.assertRaisesRegex(ValueError, "No Mach-O"):
            check_bundle(self.app, self.inspect)

    def test_framework_directory_links_must_stay_inside_bundle(self):
        frameworks = self.app / "Contents/Frameworks"
        frameworks.mkdir()
        internal = self.binary.parent / "Current"
        internal.symlink_to(".", target_is_directory=True)
        self.assertEqual(len(check_bundle(self.app, self.inspect)["binaries"]), 1)
        external = self.root / "External.framework"
        external.mkdir()
        (external / "External").write_bytes(self.binary.read_bytes())
        (frameworks / external.name).symlink_to(external, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "outside"):
            check_bundle(self.app, self.inspect)


if __name__ == "__main__":
    unittest.main()
