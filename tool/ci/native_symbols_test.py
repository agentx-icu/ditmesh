import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
import uuid
import zlib

import native_symbols as symbols


GUID = uuid.UUID("173c9081-7855-42c4-bd39-f225557e1c26")


def pdb_fixture(path, guid=GUID, age=3):
    # MSF7 superblock, directory block map, two streams; info is stream 1.
    data = bytearray(512 * 6)
    data[:32] = b"Microsoft C/C++ MSF 7.00\r\n\x1aDS\0\0\0"
    struct.pack_into("<6I", data, 32, 512, 1, 6, 16, 0, 2)
    struct.pack_into("<I", data, 512 * 2, 3)
    struct.pack_into("<4I", data, 512 * 3, 2, 0, 28, 4)
    struct.pack_into("<3I", data, 512 * 4, 20000404, 0, age)
    data[512 * 4 + 12:512 * 4 + 28] = guid.bytes_le
    path.write_bytes(data)


def pe_fixture(path, guid=GUID, age=3):
    data = bytearray(1536)
    data[:2] = b"MZ"
    struct.pack_into("<I", data, 60, 128)
    data[128:132] = b"PE\0\0"
    struct.pack_into("<HH", data, 132, 0x8664, 1)
    struct.pack_into("<H", data, 148, 240)
    optional = 152
    struct.pack_into("<H", data, optional, 0x20b)
    struct.pack_into("<I", data, optional + 108, 16)
    struct.pack_into("<II", data, optional + 112 + 48, 0x1000, 28)
    data[392:400] = b".rdata\0\0"
    struct.pack_into("<4I", data, 400, 1024, 0x1000, 1024, 512)
    cv = b"RSDS" + guid.bytes_le + struct.pack("<I", age) + b"original-build.pdb\0"
    struct.pack_into("<IIHHIIII", data, 512, 0, 0, 0, 0, 2, len(cv), 0x101c, 540)
    data[540:540 + len(cv)] = cv
    path.write_bytes(data)


def elf_fixture(path, link=None):
    data = bytearray(1024)
    data[:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<H", data, 18, 62)
    struct.pack_into("<Q", data, 40, 512)
    struct.pack_into("<HHH", data, 58, 64, 5, 1)
    names = b"\0.shstrtab\0.note.gnu.build-id\0.debug_info\0.gnu_debuglink\0"
    data[64:64 + len(names)] = names
    note = struct.pack("<III", 4, 20, 3) + b"GNU\0" + bytes(range(20))
    data[128:128 + len(note)] = note
    data[192:196] = b"test"
    sections = [(0, 0, 0, 0), (1, 3, 64, len(names)), (11, 7, 128, len(note)), (30, 1, 192, 4)]
    # The offsets deliberately come from the real string table, not constants.
    sections = [(name, kind, start, length) if i == 0 else
                (names.index((b".shstrtab", b".note.gnu.build-id", b".debug_info")[i - 1]), kind, start, length)
                for i, (name, kind, start, length) in enumerate(sections)]
    raw = b""
    if link:
        raw = link[0].encode() + b"\0"
        raw += b"\0" * (-len(raw) % 4) + struct.pack("<I", link[1])
        data[208:208 + len(raw)] = raw
    sections.append((names.index(b".gnu_debuglink"), 1, 208, len(raw)))
    for i, (name, kind, start, length) in enumerate(sections):
        struct.pack_into("<IIQQQQIIQQ", data, 512 + i * 64, name, kind, 0, 0, start, length, 0, 0, 1, 0)
    path.write_bytes(data)


class NativeSymbolTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="native symbol pairing ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_msvc_release_cache_preserves_optimization_and_symbol_flags_without_path_conversion(self):
        cache = self.root / "CMakeCache.txt"
        valid = ("CMAKE_C_FLAGS_RELEASE:STRING=/O2 /Ob2 /DNDEBUG /Zi\n"
                 "CMAKE_CXX_FLAGS_RELEASE:STRING=/O2 /Ob2 /DNDEBUG /Zi\n"
                 "CMAKE_SHARED_LINKER_FLAGS_RELEASE:STRING=/INCREMENTAL:NO /DEBUG:FULL /OPT:REF /OPT:ICF\n")
        cache.write_text(valid)
        self.assertIn('/O2', symbols.verify_msvc_flags(cache)['CMAKE_CXX_FLAGS_RELEASE'])
        for broken in (valid.replace('/O2', 'C:/Program Files/Git/O2'), valid.replace('/O2', '/Od'),
                       valid.replace('/DNDEBUG ', ''), valid.replace('/Zi', ''),
                       valid.replace('/DEBUG:FULL', '/DEBUG:FASTLINK')):
            cache.write_text(broken)
            with self.subTest(broken=broken), self.assertRaisesRegex(ValueError, 'MSVC Release options'):
                symbols.verify_msvc_flags(cache)

    def test_pe_pdb_guid_and_age_pair_and_reject_other_builds(self):
        binary, pdb = self.root / "ffi.dll", self.root / "ffi.pdb"
        pe_fixture(binary)
        pdb_fixture(pdb)
        output = self.root / "symbols"
        report = symbols.capture(binary, "windows", output, pdb=pdb)
        self.assertEqual(report["identity"]["guid"], str(GUID))
        self.assertEqual(report["identity"]["age"], 3)
        self.assertTrue(symbols.verify(binary, output / "symbols.json")["passed"])
        for guid, age in ((GUID, 4), (uuid.UUID(int=7), 3)):
            with self.subTest(guid=guid, age=age):
                pe_fixture(binary, guid, age)
                with self.assertRaisesRegex(ValueError, "different build identities"):
                    symbols.verify(binary, output / "symbols.json")

    def test_symbol_byte_corruption_rejected_even_with_same_guid(self):
        binary, pdb = self.root / "ffi.dll", self.root / "ffi.pdb"
        pe_fixture(binary)
        pdb_fixture(pdb)
        output = self.root / "symbols"
        symbols.capture(binary, "windows", output, pdb=pdb)
        with (output / "ffi.pdb").open("r+b") as stream:
            stream.seek(-1, 2)
            stream.write(b"X")
        with self.assertRaisesRegex(ValueError, "symbol bytes changed"):
            symbols.verify(binary, output / "symbols.json")

    def test_missing_mismatched_or_truncated_native_symbols_fail_closed(self):
        binary, pdb = self.root / "ffi.dll", self.root / "ffi.pdb"
        pe_fixture(binary)
        with self.assertRaises(FileNotFoundError):
            symbols.capture(binary, "windows", self.root / "missing", pdb=pdb)
        pdb_fixture(pdb, age=4)
        with self.assertRaisesRegex(ValueError, "GUID/age"):
            symbols.capture(binary, "windows", self.root / "wrong", pdb=pdb)
        pdb.write_bytes(b"truncated")
        with self.assertRaisesRegex(ValueError, "MSF7"):
            symbols.pdb_identity(pdb)
        binary.write_bytes(b"MZ")
        with self.assertRaises(ValueError):
            symbols.pe_identity(binary)

    def test_symbols_cannot_escape_their_manifest_directory(self):
        binary, pdb = self.root / "ffi.dll", self.root / "ffi.pdb"
        pe_fixture(binary)
        pdb_fixture(pdb)
        output = self.root / "symbols"
        report = symbols.capture(binary, "windows", output, pdb=pdb)
        report["symbols"] = "../ffi.pdb"
        (output / "symbols.json").write_text(json.dumps(report))
        with self.assertRaisesRegex(ValueError, "escaping"):
            symbols.verify(binary, output / "symbols.json")

    def test_elf_debuglink_name_and_crc_are_required_even_with_matching_build_id(self):
        debug, binary = self.root / "ffi.debug", self.root / "ffi.so"
        elf_fixture(debug)
        report = {"platform": "linux", "symbols": debug.name,
                  "symbol_hashes": symbols.symbol_hashes(debug), "identity": symbols.elf_identity(debug)}
        manifest = self.root / "symbols.json"
        manifest.write_text(json.dumps(report))
        crc = zlib.crc32(debug.read_bytes())
        elf_fixture(binary, (debug.name, crc))
        self.assertTrue(symbols.verify(binary, manifest)["passed"])
        for name, bad_crc in (("other.debug", crc), (debug.name, crc ^ 1)):
            elf_fixture(binary, (name, bad_crc))
            with self.assertRaisesRegex(ValueError, "name/CRC"):
                symbols.verify(binary, manifest)
        elf_fixture(binary)
        with self.assertRaisesRegex(ValueError, "debuglink"):
            symbols.verify(binary, manifest)

    @unittest.skipUnless(sys.platform == "win32", "Windows MSVC native toolchain")
    def test_actual_optimized_msvc_dll_has_matching_full_pdb(self):
        (self.root / "fixture.cpp").write_text('extern "C" __declspec(dllexport) int own_symbol(int x) { return x + 7; }\n')
        (self.root / "CMakeLists.txt").write_text('''cmake_minimum_required(VERSION 3.16)
project(symbol_fixture LANGUAGES CXX)
if(NOT MSVC)
  message(FATAL_ERROR "MSVC is required")
endif()
add_library(fixture SHARED fixture.cpp)
target_compile_options(fixture PRIVATE /Zi)
target_link_options(fixture PRIVATE /DEBUG:FULL /OPT:REF /OPT:ICF)
''')
        build = self.root / "build"
        subprocess.run(["cmake", "-S", str(self.root), "-B", str(build), "-A", "x64"], check=True)
        subprocess.run(["cmake", "--build", str(build), "--config", "Release"], check=True)
        binary = build / "Release/fixture.dll"
        output = self.root / "symbols"
        symbols.capture(binary, "windows", output, pdb=build / "Release/fixture.pdb")
        self.assertTrue(symbols.verify(binary, output / "symbols.json")["passed"])

    @unittest.skipUnless(sys.platform == "linux", "Linux native toolchain")
    def test_actual_optimized_elf_pairs_stripped_binary_and_symbolizes_function(self):
        source, binary = self.root / "fixture.c", self.root / "fixture.so"
        source.write_text("int release_symbol_fixture(int x) { return x + 7; }\n")
        subprocess.run(["cc", "-g", "-O2", "-shared", "-fPIC", "-Wl,--build-id", str(source), "-o", str(binary)], check=True)
        output = self.root / "symbols"
        report = symbols.capture(binary, "linux", output)
        self.assertTrue(report["identity"]["build_id"])
        self.assertTrue(symbols.verify(binary, output / "symbols.json")["passed"])
        nm = subprocess.run(["nm", "-D", "--defined-only", str(binary)], check=True, capture_output=True, text=True).stdout
        address = next(line.split()[0] for line in nm.splitlines() if line.endswith(" release_symbol_fixture"))
        readable = subprocess.run(["addr2line", "-f", "-e", str(output / "fixture.so.debug"), address],
                                  check=True, capture_output=True, text=True).stdout
        self.assertIn("release_symbol_fixture", readable)
        self.assertIn("fixture.c:1", readable)

    @unittest.skipUnless(sys.platform == "darwin", "Apple native toolchain")
    def test_actual_optimized_macho_pairs_dsym_and_rejects_rebuild(self):
        source, binary = self.root / "fixture.c", self.root / "fixture.dylib"
        def build(value):
            source.write_text(f"int release_symbol_fixture(int x) {{ return x + {value}; }}\n")
            obj = self.root / "fixture.o"
            subprocess.run(["xcrun", "clang", "-g", "-O2", "-c", str(source), "-o", str(obj)], check=True)
            subprocess.run(["xcrun", "clang", "-g", "-dynamiclib", str(obj), "-o", str(binary)], check=True)
        build(7)
        output = self.root / "symbols"
        symbols.capture(binary, "macos", output)
        self.assertTrue(symbols.verify(binary, output / "symbols.json")["passed"])
        build(9)
        with self.assertRaisesRegex(ValueError, "different build identities"):
            symbols.verify(binary, output / "symbols.json")


if __name__ == "__main__":
    unittest.main()
