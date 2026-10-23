"""Architecture faults in engines/plugins must fail even when the FFI matches."""
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

from native_payload import check_android, check_tree


def elf(machine=183, align=0x4000, loads=1):
    data = bytearray(120)
    data[:7] = b'\x7fELF\x02\x01\x01'
    struct.pack_into('<HHIQQQIHHHHHH', data, 16,
                     3, machine, 1, 0, 64, 0, 0, 64, 56, loads, 0, 0, 0)
    struct.pack_into('<IIQQQQQQ', data, 64, 1, 5, 0, 0, 0, 120, 120, align)
    return data


def pe(machine=0x8664):
    data = bytearray(96)
    data[:2] = b'MZ'
    struct.pack_into('<I', data, 60, 64)
    data[64:68] = b'PE\0\0'
    struct.pack_into('<H', data, 68, machine)
    return data


def macho(cpu=0x100000c):
    return struct.pack('<IIIIIIII', 0xfeedfacf, cpu, 0, 2, 0, 0, 0, 0)


class NativePayloadTests(unittest.TestCase):
    def test_all_payloads_match_not_only_backend(self):
        for format_name, arch, valid, invalid in (
                ('pe', 'x86_64', pe(), pe(0xaa64)),
                ('elf', 'x86_64', elf(62), elf()),
                ('macho', 'arm64', macho(), macho(0x1000007))):
            with self.subTest(format=format_name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / 'app').write_bytes(valid)
                (root / 'engine').write_bytes(valid)
                self.assertEqual(len(check_tree(root, format_name, arch)), 2)
                (root / 'plugin').write_bytes(invalid)
                with self.assertRaisesRegex(ValueError, 'plugin.*architecture'):
                    check_tree(root, format_name, arch)

    def test_empty_truncated_foreign_format_and_escaping_symlink_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'payload'
            root.mkdir()
            with self.assertRaisesRegex(ValueError, 'No native'):
                check_tree(root, 'pe', 'x86_64')
            (root / 'app').write_bytes(b'MZ')
            with self.assertRaises(ValueError):
                check_tree(root, 'pe', 'x86_64')
            (root / 'app').write_bytes(elf(62))
            with self.assertRaisesRegex(ValueError, 'format'):
                check_tree(root, 'pe', 'x86_64')
            (root / 'outside').symlink_to(Path(tmp) / 'outside')
            with self.assertRaisesRegex(ValueError, 'outside'):
                check_tree(root, 'elf', 'x86_64')

    def test_fat_macho_checks_slice_not_only_table(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'app'
            table = struct.pack('>II', 0xcafebabe, 1)
            table += struct.pack('>IIIII', 0x100000c, 0, 28, 32, 0)
            path.write_bytes(table + macho())
            self.assertEqual(len(check_tree(tmp, 'macho', 'arm64')), 1)
            path.write_bytes(table + macho(0x1000007))
            with self.assertRaisesRegex(ValueError, 'slice'):
                check_tree(tmp, 'macho', 'arm64')

    def test_truncated_headers_and_invalid_fat_tables(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'app'
            for data, kind in ((macho()[:28], 'macho'), (pe()[:80], 'pe')):
                path.write_bytes(data)
                with self.assertRaises(ValueError):
                    check_tree(tmp, kind, 'arm64')
            invalid_pe = pe()
            struct.pack_into('<I', invalid_pe, 60, 4)
            invalid_pe[4:8] = b'PE\0\0'
            path.write_bytes(invalid_pe)
            with self.assertRaises(ValueError):
                check_tree(tmp, 'pe', 'x86_64')
            for duplicate in (False, True):
                cpus = (0x100000c, 0x100000c if duplicate else 0x1000007)
                entries = b''.join(struct.pack('>IIQQII', cpu, 0, 72, 32, 0, 0)
                                   for cpu in cpus)
                path.write_bytes(struct.pack('>II', 0xcafebabf, 2) + entries + macho())
                with self.assertRaisesRegex(ValueError, 'overlapping|Duplicate'):
                    check_tree(tmp, 'macho', 'arm64')

    def test_required_entry_cannot_be_a_non_native_placeholder(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'plugin.dll').write_bytes(pe())
            (root / 'app').write_text('not a real runner')
            with self.assertRaisesRegex(ValueError, 'main executable'):
                check_tree(root, 'pe', 'x86_64', entry='app')

    def test_dangling_links_and_corrupt_versioned_libraries_are_not_skipped(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'app').write_bytes(elf(62))
            (root / 'libplugin.so.1').write_bytes(b'corrupted')
            with self.assertRaisesRegex(ValueError, 'native format'):
                check_tree(root, 'elf', 'x86_64')
            (root / 'libplugin.so.1').unlink()
            (root / 'missing').symlink_to(root / 'nonexistent')
            with self.assertRaisesRegex(ValueError, 'Dangling'):
                check_tree(root, 'elf', 'x86_64')

    def android(self, root, mutate=None, bundle=False):
        archive = root / ('app.aab' if bundle else 'app.apk')
        prefix = 'base/lib' if bundle else 'lib'
        payloads = {'arm64-v8a': elf(), 'x86_64': elf(62)}
        if mutate:
            mutate(payloads)
        with zipfile.ZipFile(archive, 'w') as stream:
            for abi, data in payloads.items():
                for name in ('libapp.so', 'libflutter.so', 'libtim2tox_ffi.so'):
                    stream.writestr(f'{prefix}/{abi}/{name}', data)
        return archive

    def test_android_all_native_libraries_in_apk_and_bundle(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for bundle in (False, True):
                self.assertEqual(len(check_android(self.android(root, bundle=bundle))), 6)
            for invalid in (elf(62), elf(align=4096), elf(loads=0), b'not ELF'):
                with self.subTest(invalid=invalid[:8]):
                    archive = self.android(root, lambda p: p.update({'arm64-v8a': invalid}))
                    with self.assertRaises(ValueError):
                        check_android(archive)


if __name__ == '__main__':
    unittest.main()
