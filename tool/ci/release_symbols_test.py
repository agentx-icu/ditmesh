import io
import json
from pathlib import Path
import struct
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from native_symbols import capture
from native_symbols_test import pe_fixture, pdb_fixture
import release_symbols as release


class ReleaseSymbolTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="final release symbols ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        override = patch.object(release, "REPO", self.root)
        override.start()
        self.addCleanup(override.stop)

    def test_final_zip_pairs_actual_runner_and_ffi_and_rejects_other_build(self):
        stage = self.root / "stage"
        stage.mkdir()
        for label, name in (("runner", "ditmesh.exe"), ("ffi", "tim2tox_ffi.dll")):
            binary, pdb = stage / name, stage / (name + ".pdb")
            pe_fixture(binary)
            pdb_fixture(pdb)
            capture(binary, "windows", self.root / "build/release-symbols/windows-x64" / label, pdb=pdb)
        dart = self.root / "build/dart-symbols/windows-x64"
        dart.mkdir(parents=True)
        (dart / "app.windows-x64.symbols").write_bytes(b"generated debugging bytes")
        dist = self.root / "dist/windows"
        dist.mkdir(parents=True)
        (dist / "release.msi").write_bytes(b"MSI paired separately after actual installation")
        def package():
            with zipfile.ZipFile(dist / "release.zip", "w") as archive:
                for file in ("ditmesh.exe", "tim2tox_ffi.dll"):
                    archive.write(stage / file, "ditmesh/" + file)
                archive.writestr("ditmesh/data/app.so", b"exact final AOT bytes")
        package()
        with patch.object(release, "build_metadata", return_value={"engine": "test revision"}):
            result = release.packages("windows", "x86_64")
            zipped = next(row for row in result["packages"] if row["name"].endswith(".zip"))
            self.assertEqual(len(zipped["native"]), 2)
            self.assertTrue(all(row["passed"] for row in zipped["native"].values()))
            self.assertIn("app.windows-x64.symbols", zipped["dart_split_debug_info"])
            pe_fixture(stage / "tim2tox_ffi.dll", age=4)
            package()
            with self.assertRaisesRegex(ValueError, "different build identities"):
                release.packages("windows", "x86_64")

    def test_zip_reader_selects_exact_unique_entry_without_extracting_other_paths(self):
        path = self.root / "payload.zip"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("ditmesh/ffi.dll", b"native bytes")
            archive.writestr("../must-not-exist", b"irrelevant path")
        self.assertEqual(release.read_zip(path, ["ditmesh/ffi.dll"]), {"ditmesh/ffi.dll": b"native bytes"})
        self.assertFalse((self.root.parent / "must-not-exist").exists())
        with zipfile.ZipFile(path, "a") as archive:
            archive.writestr("ditmesh/ffi.dll", b"duplicate")
        with self.assertRaisesRegex(ValueError, "duplicate"):
            release.read_zip(path, ["ditmesh/ffi.dll"])

    def test_tar_reader_rejects_link_duplicate_and_missing_native_bytes(self):
        path = self.root / "payload.tar"
        for kind in ("link", "duplicate", "missing"):
            with self.subTest(kind=kind):
                with tarfile.open(path, "w") as archive:
                    if kind == "missing":
                        continue
                    member = tarfile.TarInfo("./opt/ditmesh/ffi.so")
                    if kind == "link":
                        member.type, member.linkname = tarfile.SYMTYPE, "/external"
                        archive.addfile(member)
                    else:
                        member.size = 1
                        archive.addfile(member, io.BytesIO(b"X"))
                        archive.addfile(member, io.BytesIO(b"X"))
                with self.assertRaises(ValueError):
                    release.read_tar(path, ["opt/ditmesh/ffi.so"])

    def test_rpm_newc_reader_verifies_real_file_mode_and_rejects_truncation(self):
        def entry(name, content, mode=0o100755):
            name = name.encode() + b"\0"
            fields = [1, mode, 0, 0, 1, 0, len(content), 0, 0, 0, 0, len(name), 0]
            raw = b"070701" + b"".join(f"{value:08x}".encode() for value in fields) + name
            raw += b"\0" * (-len(raw) % 4)
            return raw + content + b"\0" * (-len(content) % 4)
        path = self.root / "payload.cpio"
        path.write_bytes(entry("./opt/ditmesh/ffi.so", b"native") + entry("TRAILER!!!", b""))
        self.assertEqual(release.read_cpio(path, ["opt/ditmesh/ffi.so"])["opt/ditmesh/ffi.so"], b"native")
        path.write_bytes(entry("./opt/ditmesh/ffi.so", b"external", 0o120777) + entry("TRAILER!!!", b""))
        with self.assertRaisesRegex(ValueError, "Invalid"):
            release.read_cpio(path, ["opt/ditmesh/ffi.so"])
        path.write_bytes(b"070701")
        with self.assertRaisesRegex(ValueError, "Invalid"):
            release.read_cpio(path, ["opt/ditmesh/ffi.so"])

    def test_absent_dart_debug_info_and_wrong_release_asset_count_fail(self):
        directory = self.root / "no-debug-files"
        directory.mkdir()
        with self.assertRaisesRegex(ValueError, "split debugging"):
            release.dart_metadata(directory)
        with self.assertRaisesRegex(ValueError, "package set"):
            release.packages("android", "arm64")

    def test_debug_symbols_in_runnable_zip_are_rejected(self):
        path = self.root / "payload.zip"
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("ditmesh/ffi.dll", b"native")
            archive.writestr("ditmesh/ditmesh.pdb", b"symbols must be separate")
        with self.assertRaisesRegex(ValueError, "outside runnable"):
            release.read_zip(path, ["ditmesh/ffi.dll"])

    def test_native_cache_mapping_requires_all_android_and_ios_slices(self):
        android = release.native_pairs("android", self.root / "native", self.root / "symbols")
        self.assertEqual(len(android), 3)
        self.assertEqual({manifest.parent.name for _, manifest in android}, set(release.ABIS))
        ios = release.native_pairs("ios", self.root / "native", self.root / "symbols")
        self.assertEqual(len(ios), 2)
        self.assertEqual({binary.parts[-3] for binary, _ in ios}, {"ios-device", "ios-simulator"})


if __name__ == "__main__":
    unittest.main()
