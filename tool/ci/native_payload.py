#!/usr/bin/env python3
"""Check actual executable headers, independently of runner/filename labels.

PE: learn.microsoft.com/windows/win32/debug/pe-format
ELF: refspecs.linuxfoundation.org/elf/gabi4+/ch4.eheader.html
Mach-O: github.com/apple-oss-distributions/xnu/tree/main/EXTERNAL_HEADERS/mach-o
"""
import argparse
import json
import mmap
from pathlib import Path
import re
import struct
import sys
import zipfile

from macos_runtime import MACHO_MAGICS

CPUS = {'pe': {0x8664: 'x86_64', 0xaa64: 'arm64', 0x14c: 'x86'},
        'elf': {62: 'x86_64', 183: 'arm64', 40: 'arm', 3: 'x86'},
        'macho': {0x1000007: 'x86_64', 0x100000c: 'arm64', 12: 'arm', 7: 'x86'}}
ANDROID_ABIS = {'arm64-v8a': 'arm64', 'armeabi-v7a': 'arm', 'x86_64': 'x86_64'}


def native_format(data):
    data = bytes(data[:4])
    if data[:2] == b'MZ':
        return 'pe'
    if data[:4] == b'\x7fELF':
        return 'elf'
    if data[:4] in MACHO_MAGICS:
        return 'macho'
    return None


def architectures(data, format_name):
    if format_name == 'pe':
        offset = struct.unpack_from('<I', data, 60)[0]
        if offset < 64 or offset + 24 > len(data):
            raise ValueError('Invalid PE/COFF header bounds')
        if data[offset:offset + 4] != b'PE\0\0':
            raise ValueError('Invalid PE signature')
        machine = struct.unpack_from('<H', data, offset + 4)[0]
    elif format_name == 'elf':
        if data[4] not in (1, 2) or data[5] not in (1, 2):
            raise ValueError('Invalid ELF class/endianness')
        machine = struct.unpack_from('<H' if data[5] == 1 else '>H', data, 18)[0]
        expected_class = 2 if machine in (62, 183) else 1
        if data[4] != expected_class or len(data) < (64 if data[4] == 2 else 52):
            raise ValueError('ELF class/header contradicts CPU')
    else:
        magic = bytes(data[:4])
        endian = '<' if magic in (bytes.fromhex('cefaedfe'), bytes.fromhex('cffaedfe'),
                                  bytes.fromhex('bebafeca'), bytes.fromhex('bfbafeca')) else '>'
        if magic in {bytes.fromhex(v) for v in ('cafebabe', 'bebafeca', 'cafebabf', 'bfbafeca')}:
            count = struct.unpack_from(endian + 'I', data, 4)[0]
            wide = magic in {bytes.fromhex('cafebabf'), bytes.fromhex('bfbafeca')}
            if not 0 < count <= 32:
                raise ValueError('Invalid Mach-O slice count')
            result = set()
            ranges = []
            for index in range(count):
                entry = struct.unpack_from(endian + ('IIQQII' if wide else 'IIIII'),
                                           data, 8 + index * (32 if wide else 20))
                cpu, _, offset, size = entry[:4]
                if offset < 8 + count * (32 if wide else 20) or size < 28 or offset + size > len(data):
                    raise ValueError('Invalid Mach-O slice bounds')
                if CPUS['macho'].get(cpu) in result or any(
                        offset < end and offset + size > start for start, end in ranges):
                    raise ValueError('Duplicate/overlapping Mach-O slices')
                ranges.append((offset, offset + size))
                sliced = memoryview(data)[offset:offset + size]
                try:
                    if bytes(sliced[:4]) not in {bytes.fromhex(v) for v in (
                            'feedface', 'cefaedfe', 'feedfacf', 'cffaedfe')}:
                        raise ValueError('Invalid Mach-O slice format')
                    actual = architectures(sliced, 'macho')
                finally:
                    sliced.release()
                if actual != {CPUS['macho'].get(cpu)}:
                    raise ValueError('Mach-O slice contradicts architecture table')
                result.update(actual)
            return result
        if len(data) < (32 if magic in {bytes.fromhex('feedfacf'), bytes.fromhex('cffaedfe')} else 28):
            raise ValueError('Truncated Mach-O header')
        machine = struct.unpack_from(endian + 'I', data, 4)[0]
    if machine not in CPUS[format_name]:
        raise ValueError(f'Unknown {format_name} CPU {machine:#x}')
    return {CPUS[format_name][machine]}


def verify(data, format_name, arch, label):
    try:
        if native_format(data) != format_name:
            raise ValueError(f'Expected {format_name} format')
        actual = architectures(data, format_name)
        if arch not in actual:
            raise ValueError(f'architecture {sorted(actual)} cannot run as {arch}')
        return {'path': label, 'architectures': sorted(actual)}
    except (ValueError, IndexError, struct.error) as error:
        raise ValueError(f'{label}: {error}') from error


def check_tree(directory, format_name, arch, entry=None):
    root = Path(directory).resolve()
    if entry:
        executable = root / entry
        if not executable.is_file() or not executable.resolve().is_relative_to(root):
            raise ValueError(f'Main executable missing or outside root: {entry}')
        with executable.open('rb') as stream:
            if native_format(stream.read(4)) != format_name:
                raise ValueError(f'{entry}: main executable has no {format_name} header')
    result, seen = [], set()
    for path in sorted(root.rglob('*')):
        resolved = path.resolve()
        if not resolved.is_relative_to(root):
            raise ValueError(f'Payload path resolves outside root: {path}')
        if path.is_symlink() and not path.exists():
            raise ValueError(f'Dangling payload symlink: {path}')
        if not path.is_file() or resolved in seen:
            continue
        seen.add(resolved)
        with resolved.open('rb') as stream:
            if not native_format(stream.read(4)):
                if path.suffix.lower() in ('.dll', '.exe', '.so', '.dylib') or re.search(
                        r'\.so(?:\.|$)', path.name):
                    raise ValueError(f'{path}: missing native format header')
                continue
            with mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
                result.append(verify(data, format_name, arch, str(path.relative_to(root))))
    if not result:
        raise ValueError('No native runtime binaries found')
    return result


def check_elf_pages(data, label):
    """Every 64-bit Android PT_LOAD, including Flutter/plugin prebuilts."""
    if data[4] != 2:
        return
    endian = '<' if data[5] == 1 else '>'
    offset = struct.unpack_from(endian + 'Q', data, 32)[0]
    size, count = struct.unpack_from(endian + 'HH', data, 54)
    if size != 56 or count == 0 or offset + size * count > len(data):
        raise ValueError(f'{label}: invalid ELF program headers')
    loads = 0
    for index in range(count):
        kind, _, file_offset, address, _, _, _, align = struct.unpack_from(
            endian + 'IIQQQQQQ', data, offset + size * index)
        if kind == 1:
            loads += 1
            if align < 16384 or align & (align - 1) or (address - file_offset) % align:
                raise ValueError(f'{label}: PT_LOAD is not 16 KB aligned')
    if not loads:
        raise ValueError(f'{label}: no ELF PT_LOAD segments')


def check_android(archive):
    result = []
    with zipfile.ZipFile(archive) as stream:
        names = stream.namelist()
        if len(names) != len(set(names)):
            raise ValueError(f'{archive}: duplicate ZIP entries')
        for name in names:
            if not name.endswith('.so'):
                continue
            parts = name.split('/')
            # AAB feature modules and base, or the APK root lib directory.
            if 'lib' not in parts:
                raise ValueError(f'{name}: unclassified native library')
            pos = parts.index('lib')
            abi = parts[pos + 1] if pos + 1 < len(parts) else ''
            if abi not in ANDROID_ABIS:
                raise ValueError(f'{name}: unsupported Android ABI')
            data = stream.read(name)
            result.append(verify(data, 'elf', ANDROID_ABIS[abi], name))
            check_elf_pages(data, name)
    if not result:
        raise ValueError(f'{archive}: no native libraries')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path', type=Path)
    parser.add_argument('--format', choices=('elf', 'pe', 'macho', 'android'), required=True)
    parser.add_argument('--entry', help='required main executable relative to payload root')
    parser.add_argument('--arch', choices=('x86_64', 'arm64', 'arm', 'x86'))
    args = parser.parse_args()
    if args.format != 'android' and not args.arch:
        parser.error('--arch is required for a native directory')
    result = check_android(args.path) if args.format == 'android' else check_tree(
        args.path, args.format, args.arch, args.entry)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, struct.error, zipfile.BadZipFile) as error:
        print(f'Native payload: {error}', file=sys.stderr)
        sys.exit(1)
