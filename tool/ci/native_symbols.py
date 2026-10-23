#!/usr/bin/env python3
"""Keep symbols from this build and verify their native binary identity.

This operates on build outputs, never application crash dumps or user data.
ELF build IDs, PE/PDB GUID+age and Mach-O UUIDs are build identities, not a
claim that a crash reporter or vendor symbols have been configured.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import uuid
import zlib


def checked_slice(data, offset, size):
    if offset < 0 or size < 0 or offset + size > len(data):
        raise ValueError("Truncated native symbol metadata")
    return data[offset:offset + size]


def u32(data, offset):
    return struct.unpack("<I", checked_slice(data, offset, 4))[0]


def sha256(path):
    with Path(path).open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def verify_msvc_flags(cache):
    values = {}
    for line in Path(cache).read_text(encoding="utf-8").splitlines():
        if not line.startswith(("#", "//")) and ":" in line and "=" in line:
            key, value = line.split("=", 1)
            values[key.split(":", 1)[0]] = value
    expected = {"CMAKE_C_FLAGS_RELEASE": "/O2 /Ob2 /DNDEBUG /Zi",
                "CMAKE_CXX_FLAGS_RELEASE": "/O2 /Ob2 /DNDEBUG /Zi",
                "CMAKE_SHARED_LINKER_FLAGS_RELEASE": "/INCREMENTAL:NO /DEBUG:FULL /OPT:REF /OPT:ICF"}
    for key, value in expected.items():
        if values.get(key) != value:
            raise ValueError("MSVC Release options were missing or changed before compilation: " + key)
    return expected


def elf_identity(path, require_debug=False):
    data = Path(path).read_bytes()
    if data[:4] != b"\x7fELF" or data[4:6] not in (b"\x01\x01", b"\x02\x01"):
        raise ValueError("Expected little-endian ELF32/ELF64")
    wide = data[4] == 2
    off = struct.unpack("<Q" if wide else "<I", checked_slice(data, 40 if wide else 32, 8 if wide else 4))[0]
    size, count, names_index = struct.unpack("<HHH", checked_slice(data, 58 if wide else 46, 6))
    fmt = "<IIQQQQIIQQ" if wide else "<IIIIIIIIII"
    expected_size = struct.calcsize(fmt)
    if size != expected_size or not count or names_index >= count:
        raise ValueError("Unsupported ELF section table")
    sections = [struct.unpack(fmt, checked_slice(data, off + n * size, size)) for n in range(count)]
    names = checked_slice(data, sections[names_index][4], sections[names_index][5])
    build_ids = []
    has_debug = False
    for section in sections:
        name_offset, kind, _, _, start, length, *_ = section
        if name_offset >= len(names):
            raise ValueError("Invalid ELF section name")
        end = names.find(b"\0", name_offset)
        if end < 0:
            raise ValueError("Unterminated ELF section name")
        name = names[name_offset:end]
        has_debug |= name in (b".debug_info", b".zdebug_info") and length > 0
        if kind != 7:
            continue
        notes = checked_slice(data, start, length)
        cursor = 0
        while cursor < len(notes):
            name_size, desc_size, note_type = struct.unpack("<III", checked_slice(notes, cursor, 12))
            cursor += 12
            owner = checked_slice(notes, cursor, name_size)
            cursor += (name_size + 3) & ~3
            desc = checked_slice(notes, cursor, desc_size)
            cursor += (desc_size + 3) & ~3
            if owner == b"GNU\0" and note_type == 3:
                build_ids.append(desc.hex())
    if len(build_ids) != 1 or not build_ids[0]:
        raise ValueError("Expected exactly one GNU build ID")
    if require_debug and not has_debug:
        raise ValueError("Owned native symbols lack DWARF debug_info")
    return {"format": "elf", "build_id": build_ids[0], "machine": struct.unpack("<H", data[18:20])[0]}


def elf_debuglink(path):
    data = Path(path).read_bytes()
    # Reuse the strict ELF identity validation before reading the section table.
    elf_identity(path)
    wide = data[4] == 2
    off = struct.unpack("<Q" if wide else "<I", data[40:48] if wide else data[32:36])[0]
    size, count, names_index = struct.unpack("<HHH", data[58:64] if wide else data[46:52])
    fmt = "<IIQQQQIIQQ" if wide else "<IIIIIIIIII"
    sections = [struct.unpack(fmt, checked_slice(data, off + n * size, size)) for n in range(count)]
    names = checked_slice(data, sections[names_index][4], sections[names_index][5])
    links = []
    for section in sections:
        name = names[section[0]:].split(b"\0", 1)[0]
        if name == b".gnu_debuglink":
            raw = checked_slice(data, section[4], section[5])
            end = raw.find(b"\0")
            if end <= 0:
                raise ValueError("Invalid GNU debuglink name")
            crc_offset = (end + 1 + 3) & ~3
            if len(raw) != crc_offset + 4:
                raise ValueError("Invalid GNU debuglink CRC layout")
            name = raw[:end].decode("utf-8")
            if Path(name).name != name or name in (".", "..") or "\\" in name:
                raise ValueError("GNU debuglink must be a symbol basename")
            links.append((name, u32(raw, crc_offset)))
    if len(links) != 1:
        raise ValueError("Expected exactly one GNU debuglink")
    return links[0]


def pe_identity(path):
    data = Path(path).read_bytes()
    if data[:2] != b"MZ":
        raise ValueError("Expected PE binary")
    pe = u32(data, 60)
    if checked_slice(data, pe, 4) != b"PE\0\0":
        raise ValueError("Invalid PE signature")
    machine, sections_count = struct.unpack("<HH", checked_slice(data, pe + 4, 4))
    optional_size = struct.unpack("<H", checked_slice(data, pe + 20, 2))[0]
    optional = pe + 24
    magic = struct.unpack("<H", checked_slice(data, optional, 2))[0]
    directory = 112 if magic == 0x20b else 96 if magic == 0x10b else 0
    if not directory or optional_size < directory + 56 or u32(data, optional + directory - 4) < 7:
        raise ValueError("PE has no debug directory")
    debug_rva, debug_size = struct.unpack("<II", checked_slice(data, optional + directory + 48, 8))
    section_start = optional + optional_size
    sections = [checked_slice(data, section_start + n * 40, 40) for n in range(sections_count)]

    def file_offset(rva, length):
        for section in sections:
            virtual_size, virtual_address, raw_size, raw_pointer = struct.unpack("<IIII", section[8:24])
            if virtual_address <= rva and rva + length <= virtual_address + min(virtual_size, raw_size):
                return raw_pointer + rva - virtual_address
        raise ValueError("PE debug directory outside mapped file sections")

    if not debug_size or debug_size % 28:
        raise ValueError("Invalid PE debug directory size")
    offset = file_offset(debug_rva, debug_size)
    records = []
    for cursor in range(offset, offset + debug_size, 28):
        fields = struct.unpack("<IIHHIIII", checked_slice(data, cursor, 28))
        if fields[4] != 2:
            continue
        cv = checked_slice(data, fields[7], fields[5])
        if cv[:4] != b"RSDS" or len(cv) < 25 or b"\0" not in cv[24:]:
            raise ValueError("Expected RSDS CodeView identity")
        records.append({"format": "pe-pdb", "machine": machine,
                        "guid": str(uuid.UUID(bytes_le=cv[4:20])), "age": u32(cv, 20)})
    if len(records) != 1:
        raise ValueError("Expected exactly one PE/PDB identity")
    return records[0]


def pdb_identity(path):
    data = Path(path).read_bytes()
    if data[:32] != b"Microsoft C/C++ MSF 7.00\r\n\x1aDS\0\0\0":
        raise ValueError("Expected MSF7 PDB")
    block_size, _, block_count, directory_size, _, block_map = struct.unpack("<6I", checked_slice(data, 32, 24))
    if block_size not in (512, 1024, 2048, 4096) or block_count * block_size != len(data):
        raise ValueError("Invalid PDB block geometry")

    def pages(indices, size):
        if any(n >= block_count for n in indices):
            raise ValueError("PDB block outside file")
        return b"".join(checked_slice(data, n * block_size, block_size) for n in indices)[:size]

    count = (directory_size + block_size - 1) // block_size
    # Native toolchain PDBs use a single directory block map. Reject extended
    # layouts explicitly instead of accepting an unverified identity.
    if not count or count * 4 > block_size:
        raise ValueError("Unsupported PDB directory block map")
    blocks = struct.unpack("<" + "I" * count, checked_slice(data, block_map * block_size, count * 4))
    directory = pages(blocks, directory_size)
    stream_count = u32(directory, 0)
    if stream_count < 2 or 4 + stream_count * 4 > len(directory):
        raise ValueError("Invalid PDB stream directory")
    sizes = struct.unpack("<" + "I" * stream_count, directory[4:4 + stream_count * 4])
    cursor = 4 + stream_count * 4
    info = None
    for index, size in enumerate(sizes):
        count = 0 if size == 0xffffffff else (size + block_size - 1) // block_size
        indices = struct.unpack("<" + "I" * count, checked_slice(directory, cursor, count * 4))
        cursor += count * 4
        if index == 1:
            info = pages(indices, size)
    if info is None or len(info) < 28:
        raise ValueError("Missing PDB info stream")
    return {"guid": str(uuid.UUID(bytes_le=info[12:28])), "age": u32(info, 8)}


def macho_identity(path):
    result = subprocess.run(["xcrun", "dwarfdump", "--uuid", str(path)], check=True, text=True, capture_output=True)
    pairs = []
    for line in result.stdout.splitlines():
        match = re.fullmatch(r"UUID: ([0-9A-Fa-f-]{36}) \(([A-Za-z0-9_]+)\) .+", line)
        if not match:
            raise ValueError("Malformed Mach-O UUID output")
        pairs.append([match[2], str(uuid.UUID(match[1]))])
    if not pairs or len({arch for arch, _ in pairs}) != len(pairs):
        raise ValueError("Missing or duplicate Mach-O architecture UUID")
    return {"format": "macho", "uuids": sorted(pairs)}


def identity(path, platform, require_debug=False):
    if platform in ("linux", "android"):
        return elf_identity(path, require_debug)
    if platform == "windows":
        return pe_identity(path)
    result = macho_identity(path)
    if require_debug:
        dwarf = subprocess.run(["xcrun", "dwarfdump", "--debug-info", "--recurse-depth=1", str(path)],
                               check=True, text=True, capture_output=True)
        if "DW_TAG_compile_unit" not in dwarf.stdout:
            raise ValueError("Owned dSYM lacks DWARF compilation units")
    return result


def symbol_hashes(path):
    path = Path(path)
    if path.is_symlink():
        raise ValueError("Symbol root must not be a symlink")
    if path.is_file():
        return {path.name: sha256(path)}
    records = {}
    for item in sorted(path.rglob("*")):
        if item.is_symlink():
            raise ValueError("Unexpected link in owned symbol bundle")
        if item.is_file():
            records[item.relative_to(path).as_posix()] = sha256(item)
    if not records:
        raise ValueError("Empty native symbol bundle")
    return records


def verify(binary, manifest):
    manifest = Path(manifest)
    report = json.loads(manifest.read_text())
    root = manifest.parent.resolve()
    symbols = root / report["symbols"]
    if not symbols.resolve().is_relative_to(root) or not symbols.exists():
        raise ValueError("Missing or escaping native symbols")
    if symbol_hashes(symbols) != report["symbol_hashes"]:
        raise ValueError("Archived native symbol bytes changed")
    actual = identity(binary, report["platform"])
    if actual != report["identity"]:
        raise ValueError("Final binary and archived symbols have different build identities")
    if report["platform"] == "windows":
        expected = {k: actual[k] for k in ("guid", "age")}
        if pdb_identity(symbols) != expected:
            raise ValueError("PDB GUID/age does not match final PE")
    else:
        if identity(symbols, report["platform"], require_debug=True) != actual:
            raise ValueError("Symbols do not match final native binary")
        if report["platform"] in ("linux", "android"):
            name, crc = elf_debuglink(binary)
            if name != symbols.name or crc != zlib.crc32(symbols.read_bytes()):
                raise ValueError("GNU debuglink name/CRC does not match archived symbols")
    return {"binary": Path(binary).name, "sha256": sha256(binary), "identity": actual, "passed": True}


def capture(binary, platform, output, *, pdb=None, dsym=None, objcopy="objcopy", strip="strip"):
    binary, output = Path(binary), Path(output)
    if output.exists():
        raise ValueError("Use a fresh symbol output directory")
    before = identity(binary, platform, require_debug=platform in ("linux", "android"))
    output.mkdir(parents=True)
    if platform == "windows":
        source = Path(pdb) if pdb else binary.with_suffix(".pdb")
        symbols = output / (binary.stem + ".pdb")
        shutil.copyfile(source, symbols)
    elif platform in ("linux", "android"):
        symbols = output / (binary.name + ".debug")
        subprocess.run([objcopy, "--only-keep-debug", str(binary), str(symbols)], check=True)
        # Fail on strip errors; never silently upload a different or unverified
        # payload. Retain the GNU build ID and attach its exact debuglink.
        subprocess.run([strip, "--strip-unneeded", str(binary)], check=True)
        subprocess.run([objcopy, "--add-gnu-debuglink=" + str(symbols.resolve()), str(binary)], check=True)
    else:
        symbols = output / (binary.name + ".dSYM")
        if dsym:
            shutil.copytree(dsym, symbols, symlinks=True)
        else:
            subprocess.run(["xcrun", "dsymutil", str(binary), "-o", str(symbols)], check=True)
    if identity(binary, platform) != before:
        raise ValueError("Symbol capture changed the native build identity")
    report = {"schema": 1, "platform": platform, "binary": binary.name,
              "binary_sha256": sha256(binary), "identity": before, "symbols": symbols.name,
              "symbol_hashes": symbol_hashes(symbols)}
    manifest = output / "symbols.json"
    manifest.write_text(json.dumps(report, indent=2) + "\n")
    verify(binary, manifest)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    store = commands.add_parser("capture")
    store.add_argument("binary")
    store.add_argument("--platform", required=True, choices=["linux", "android", "windows", "macos", "ios"])
    store.add_argument("--output", required=True)
    store.add_argument("--pdb")
    store.add_argument("--dsym")
    store.add_argument("--objcopy", default="objcopy")
    store.add_argument("--strip", default="strip")
    check = commands.add_parser("verify")
    check.add_argument("binary")
    check.add_argument("--manifest", required=True)
    check.add_argument("--output")
    flags = commands.add_parser("verify-msvc-flags")
    flags.add_argument("cache")
    args = parser.parse_args()
    if args.command == "capture":
        result = capture(args.binary, args.platform, args.output, pdb=args.pdb, dsym=args.dsym,
                         objcopy=args.objcopy, strip=args.strip)
    elif args.command == "verify-msvc-flags":
        result = verify_msvc_flags(args.cache)
    else:
        result = verify(args.binary, args.manifest)
        if args.output:
            target = Path(args.output)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
