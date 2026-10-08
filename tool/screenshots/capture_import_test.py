#!/usr/bin/env python3
"""Exercise screenshot import/publish boundaries using disposable gallery copies."""

import hashlib
import os
from pathlib import Path
import shutil
import random
import struct
import zlib
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
SCRIPT = Path(os.environ.get("DITMESH_CAPTURE_TEST_SCRIPT", REPO / "tool/screenshots/capture.sh"))


def snapshot(root):
    return {
        str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in root.rglob("*")
        if path.is_file()
    }


class CaptureImportTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ditmesh_import_test_")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.output = self.root / "output"
        # Private valid PNG fixtures keep importer tests independent of the
        # capture gallery and the host's ability to run a desktop application.
        scenes = self.scenes = ("welcome", "create_identity", "backup_wizard", "chat_list",
                  "conversation", "contacts", "groups", "group_conversation",
                  "reference", "translator", "listen", "me", "network_bootstrap")
        for locale in ("en", "zh"):
            self.add_locale(locale)

    def add_locale(self, locale):
        folder = self.source / "macos" / locale
        folder.mkdir(parents=True, exist_ok=True)
        for scene in self.scenes:
            rng = random.Random(f"{locale}/{scene}")
            raw = b"".join(b"\x00" + rng.randbytes(96 * 3) for _ in range(96))
            def chunk(kind, data):
                return (struct.pack(">I", len(data)) + kind + data
                        + struct.pack(">I", zlib.crc32(kind + data)))
            png = (b"\x89PNG\r\n\x1a\n"
                   + chunk(b"IHDR", struct.pack(">IIBBBBB", 96, 96, 8, 2, 0, 0, 0))
                   + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
            (folder / f"{scene}.png").write_bytes(png)

    def test_all_ten_canonical_locales_publish_to_explicit_output(self):
        locales = ("en", "zh", "zh_Hant", "ja", "ko", "de", "fr", "es", "pt", "ru")
        for locale in locales[2:]:
            self.add_locale(locale)
        before = snapshot(self.source)
        self.run_import(extra=("--locales", ",".join(locales)))
        self.assertEqual(snapshot(self.output), before)
        self.assertEqual(snapshot(self.source), before)

    def test_each_style_and_brightness_can_publish_to_explicit_output(self):
        before = snapshot(self.source)
        for style in ("classic", "modern", "radio", "paper", "cartoon"):
            for theme in ("light", "dark", "system"):
                with self.subTest(style=style, theme=theme):
                    output = self.root / f"{style}-{theme}"
                    self.run_import(output=output, extra=("--style", style, "--theme", theme))
                    self.assertEqual(snapshot(output), before)
        self.assertEqual(snapshot(self.source), before)

    def test_all_styles_keep_separate_profile_folders(self):
        matrix = self.root / "matrix"
        for style in ("classic", "modern", "radio", "paper", "cartoon"):
            shutil.copytree(self.source, matrix / style)
        before = snapshot(matrix)
        self.run_import(source=matrix, extra=("--style", "all"))
        self.assertEqual(snapshot(self.output), before)
        self.assertEqual(snapshot(matrix), before)

    def test_custom_profile_requires_explicit_output(self):
        for args in (("--locales", "en"), ("--style", "radio"),
                     ("--style", "all"), ("--theme", "dark")):
            with self.subTest(args=args):
                result = subprocess.run(["bash", str(SCRIPT), "--from", str(self.source), *args],
                                        cwd=REPO, text=True, capture_output=True, timeout=30)
                self.assertEqual(result.returncode, 64, result.stdout + result.stderr)
                self.assertIn("explicit --out", result.stderr)
        self.assertFalse(self.output.exists())

    def test_custom_profile_cannot_overwrite_canonical_gallery(self):
        result = subprocess.run(["bash", str(SCRIPT), "--from", str(self.source),
                                 "--style", "radio", "--out", str(REPO / "doc/screenshots")],
                                cwd=REPO, text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, 64, result.stdout + result.stderr)
        self.assertIn("canonical gallery", result.stderr)

    def test_invalid_locale_style_theme_and_environment_do_not_publish(self):
        for args in (("--locales", "en,en"), ("--locales", "en,"),
                     ("--locales", "unknown"), ("--style", "unknown"),
                     ("--style", ""), ("--theme", "unknown"), ("--theme", "")):
            with self.subTest(args=args):
                self.run_import(extra=args, expected=64)
        for knob in ("DITMESH_SHOT_STYLE", "DITMESH_SHOT_THEME"):
            for value in ("unknown", ""):
                with self.subTest(knob=knob, value=value):
                    result = subprocess.run(["bash", str(SCRIPT), "--from", str(self.source),
                                             "--out", str(self.output)], cwd=REPO,
                                            env={**os.environ, knob: value},
                                            text=True, capture_output=True, timeout=30)
                    self.assertEqual(result.returncode, 64, result.stdout + result.stderr)
        self.assertFalse(self.output.exists())

    def run_import(self, *, source=None, output=None, extra=(), expected=0):
        result = subprocess.run(
            ["bash", str(SCRIPT), "--platforms", "macos", "--from",
             str(source or self.source), "--out", str(output or self.output), *extra],
            cwd=REPO, text=True, capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def protect_destination(self):
        marker = self.output / "macos/en/previous-gallery.txt"
        marker.parent.mkdir(parents=True)
        marker.write_text("previous complete capture", encoding="utf-8")
        return snapshot(self.output)

    def test_complete_capture_publishes_without_changing_source(self):
        before = snapshot(self.source)
        result = self.run_import()
        self.assertEqual(snapshot(self.output), before)
        self.assertEqual(snapshot(self.source), before)
        self.assertEqual(len(before), 26)
        self.assertIn("from completed CI capture", result.stdout)

    def test_missing_network_settings_keeps_previous_gallery(self):
        before = self.protect_destination()
        (self.source / "macos/en/network_bootstrap.png").unlink()
        self.run_import(expected=1)
        self.assertEqual(snapshot(self.output), before)

    def test_missing_frame_keeps_previous_gallery(self):
        before = self.protect_destination()
        (self.source / "macos/zh/welcome.png").unlink()
        self.run_import(expected=1)
        self.assertEqual(snapshot(self.output), before)

    def test_duplicate_frames_keep_previous_gallery(self):
        before = self.protect_destination()
        shutil.copyfile(self.source / "macos/en/welcome.png",
                        self.source / "macos/en/create_identity.png")
        self.run_import(expected=1)
        self.assertEqual(snapshot(self.output), before)

    def test_source_and_output_cannot_overlap(self):
        before = snapshot(self.source)
        for output in (self.source, self.source / "nested-output", self.root):
            with self.subTest(output=output):
                self.run_import(output=output, expected=64)
                self.assertEqual(snapshot(self.source), before)

    def test_output_root_symlink_cannot_alias_source(self):
        before = snapshot(self.source)
        self.output.symlink_to(self.source, target_is_directory=True)
        self.run_import(expected=64)
        self.assertEqual(snapshot(self.source), before)

    def test_output_locale_symlink_cannot_alias_source(self):
        before = snapshot(self.source)
        (self.output / "macos").mkdir(parents=True)
        (self.output / "macos/en").symlink_to(self.source / "macos/zh", target_is_directory=True)
        self.run_import(expected=64)
        self.assertEqual(snapshot(self.source), before)

    def test_source_locale_symlink_preserves_both_locales(self):
        # English publication would delete the Chinese source without the guard.
        seed = self.output / "macos/en/zh-seed"
        seed.parent.mkdir(parents=True)
        shutil.move(self.source / "macos/zh", seed)
        (self.source / "macos/zh").symlink_to(seed, target_is_directory=True)
        before = snapshot(self.source), snapshot(self.output)
        self.run_import(expected=64)
        self.assertEqual((snapshot(self.source), snapshot(self.output)), before)
        self.assertEqual(len(list(seed.glob("*.png"))), 13)

    def test_source_platform_symlink_is_rejected(self):
        linked = self.root / "linked-platform"
        shutil.move(self.source / "macos", linked)
        (self.source / "macos").symlink_to(linked, target_is_directory=True)
        before = snapshot(linked)
        self.run_import(expected=64)
        self.assertEqual(snapshot(linked), before)
        self.assertFalse(self.output.exists())

    def test_source_png_symlink_is_rejected(self):
        frame = self.source / "macos/en/welcome.png"
        linked = self.root / "linked-frame.png"
        shutil.move(frame, linked)
        frame.symlink_to(linked)
        before = snapshot(self.source)
        self.run_import(expected=64)
        self.assertEqual(snapshot(self.source), before)
        self.assertFalse(self.output.exists())

    def test_partial_locale_can_publish_only_to_explicit_output(self):
        before = snapshot(self.source)
        self.run_import(extra=("--locales", "en"))
        self.assertEqual(len(list(self.output.rglob("*.png"))), 13)
        self.assertFalse((self.output / "macos/zh").exists())
        self.assertEqual(snapshot(self.source), before)

    def test_invalid_import_arguments_do_not_publish(self):
        commands = (
            ("--from",), ("--from=",), ("--style",), ("--theme",), ("--locales",),
            ("--from", str(self.root / "missing")),
            ("--from", str(self.source), "--device", "macos"),
        )
        for args in commands:
            with self.subTest(args=args):
                result = subprocess.run(["bash", str(SCRIPT), *args], cwd=REPO,
                                        text=True, capture_output=True, timeout=30)
                self.assertEqual(result.returncode, 64, result.stdout + result.stderr)
        self.assertFalse(self.output.exists())

    @unittest.skipUnless(sys.platform == "darwin", "macOS case-alias protection")
    def test_macos_case_alias_cannot_overlap_source(self):
        before = snapshot(self.source)
        self.run_import(output=Path(str(self.source).swapcase()), expected=64)
        self.assertEqual(snapshot(self.source), before)


if __name__ == "__main__":
    unittest.main(verbosity=2)
