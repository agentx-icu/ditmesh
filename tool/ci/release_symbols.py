#!/usr/bin/env python3
"""Archive source-built symbols and pair them with actual release payloads.

No crash dumps, runtime logs, user files, accounts or symbol servers are read.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tarfile
import tempfile
import zipfile

from native_symbols import capture, identity, sha256, verify

REPO = Path(__file__).resolve().parents[2]
ABIS = ("arm64-v8a", "armeabi-v7a", "x86_64")


def native_pairs(target, native, symbols):
    if target == "android":
        return [(native / "jniLibs" / abi / "libtim2tox_ffi.so", symbols / abi / "symbols.json") for abi in ABIS]
    if target == "ios":
        return [(native / part / "tim2tox_ffi.framework/tim2tox_ffi",
                 symbols / part / "tim2tox_ffi/symbols.json") for part in ("ios-device", "ios-simulator")]
    name = "tim2tox_ffi.dll" if target.startswith("windows") else "libtim2tox_ffi.dylib" if target.startswith("macos") else "libtim2tox_ffi.so"
    return [(native / name, symbols / "tim2tox_ffi/symbols.json")]


def write_report(path, report):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2) + "\n")


def native(target):
    return [verify(binary, manifest) for binary, manifest in native_pairs(
        target, REPO / "build/native" / target, REPO / "build/native-symbols" / target)]


def app_paths(target, arch):
    build = REPO / "apps/ditmesh/build"
    if target == "linux":
        return "linux-x86_64", build / "linux/x64/release/bundle", {"runner": "ditmesh", "ffi": "lib/libtim2tox_ffi.so"}
    if target == "windows":
        return "windows-x64", build / "windows/x64/runner/Release", {"runner": "ditmesh.exe", "ffi": "tim2tox_ffi.dll"}
    if target == "macos":
        return "macos-" + arch, build / "macos/Build/Products/Release/DitMesh.app", {"runner": "Contents/MacOS/DitMesh", "ffi": "Contents/Frameworks/libtim2tox_ffi.dylib"}
    if target == "ios":
        return "ios", build / "ios/iphoneos/Runner.app", {"runner": "Runner", "ffi": "Frameworks/tim2tox_ffi.framework/tim2tox_ffi"}
    return "android", build, {}


def matching_dsym(binary, search):
    expected = identity(binary, "macos")
    found = [path for path in search.rglob("*.dSYM") if identity(path, "macos") == expected]
    if len(found) != 1:
        raise ValueError("Expected exactly one matching main executable dSYM")
    return found[0]


def prepare(target, arch):
    key, root, paths = app_paths(target, arch)
    output = REPO / "build/release-symbols" / key
    if output.exists():
        raise ValueError("Use fresh app symbol output")
    source = REPO / "build/native-symbols" / key
    if target == "android":
        for abi in ABIS:
            shutil.copytree(source / abi, output / abi)
        return {"native": native("android")}
    ffi = source / ("ios-device/tim2tox_ffi" if target == "ios" else "tim2tox_ffi")
    shutil.copytree(ffi, output / "ffi")
    binary = root / paths["runner"]
    kwargs = {}
    if target == "windows":
        kwargs["pdb"] = REPO / "apps/ditmesh/build/windows/x64/native-symbol-source/ditmesh.pdb"
    elif target in ("macos", "ios"):
        kwargs["dsym"] = matching_dsym(binary, REPO / "apps/ditmesh/build" / target)
    capture(binary, target, output / "runner", **kwargs)
    result = {label: verify(root / entry, output / label / "symbols.json") for label, entry in paths.items()}
    write_report(output / "built-payload.json", result)
    return result


def installed(root, symbols):
    return {label: verify(root / name, symbols / label / "symbols.json")
            for label, name in (("runner", "ditmesh.exe"), ("ffi", "tim2tox_ffi.dll"))}


def read_zip(path, entries):
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if any(name.lower().endswith((".pdb", ".debug", ".symbols")) or ".dsym/" in name.lower() for name in names):
            raise ValueError("Debug symbols must stay outside runnable release payloads")
        result = {}
        for name in entries:
            if names.count(name) != 1:
                raise ValueError("Missing or duplicate release ZIP native entry: " + name)
            info = archive.getinfo(name)
            if info.is_dir() or not 0 < info.file_size <= 512 * 1024 * 1024:
                raise ValueError("Invalid release native entry size")
            result[name] = archive.read(info)
        return result


def read_tar(path, entries):
    with tarfile.open(path, "r:*") as archive:
        result = {}
        for member in archive:
            name = member.name.removeprefix("./")
            if name not in entries:
                continue
            if name in result or not member.isfile() or not 0 < member.size <= 512 * 1024 * 1024:
                raise ValueError("Invalid or duplicate native tar entry")
            result[name] = archive.extractfile(member).read()
        if set(result) != set(entries):
            raise ValueError("Missing release native tar entry")
        return result


def read_cpio(path, entries):
    result = {}
    with path.open("rb") as stream:
        while True:
            header = stream.read(110)
            if len(header) != 110 or header[:6] not in (b"070701", b"070702"):
                raise ValueError("Invalid RPM newc payload")
            fields = [int(header[n:n + 8], 16) for n in range(6, 110, 8)]
            mode, size, length = fields[1], fields[6], fields[11]
            if not 1 <= length <= 4096 or size > 512 * 1024 * 1024:
                raise ValueError("Invalid RPM entry bounds")
            raw = stream.read(length)
            if len(raw) != length or not raw.endswith(b"\0"):
                raise ValueError("Truncated RPM path")
            name = raw[:-1].decode("utf-8").removeprefix("./")
            stream.seek((-110 - length) % 4, 1)
            if name == "TRAILER!!!":
                break
            if name in entries:
                if name in result or mode & 0o170000 != 0o100000 or size == 0:
                    raise ValueError("Invalid or duplicate RPM native entry")
                result[name] = stream.read(size)
                if len(result[name]) != size:
                    raise ValueError("Truncated RPM native entry")
            else:
                stream.seek(size, 1)
            stream.seek(-size % 4, 1)
    if set(result) != set(entries):
        raise ValueError("Missing RPM native entry")
    return result


def package_bytes(package, entries):
    if package.suffix in (".zip", ".apk", ".aab", ".ipa"):
        return read_zip(package, entries)
    if package.name.endswith(".tar.gz"):
        return read_tar(package, entries)
    with tempfile.TemporaryDirectory(prefix="release symbol package ") as temporary:
        root = Path(temporary)
        if package.suffix in (".deb", ".rpm"):
            raw = root / "payload"
            command = ["dpkg-deb", "--fsys-tarfile", str(package)] if package.suffix == ".deb" else ["rpm2cpio", str(package)]
            with raw.open("wb") as stream:
                subprocess.run(command, check=True, stdout=stream)
            return read_tar(raw, entries) if package.suffix == ".deb" else read_cpio(raw, entries)
        if package.suffix == ".pkg":
            expanded = root / "expanded"
            subprocess.run(["pkgutil", "--expand-full", str(package), str(expanded)], check=True)
            result = {}
            for entry in entries:
                hits = list(expanded.rglob(entry))
                if len(hits) != 1 or not hits[0].resolve().is_relative_to(expanded.resolve()):
                    raise ValueError("Missing, duplicate or escaping PKG native entry")
                result[entry] = hits[0].read_bytes()
            return result
    raise ValueError("Unsupported release package: " + package.name)


def dart_metadata(directory):
    files = list(directory.glob("*.symbols"))
    if not files:
        raise ValueError("Missing build-generated Dart split debugging information")
    return {file.name: sha256(file) for file in sorted(files)}


def build_metadata():
    flutter = Path(os.environ["FLUTTER_ROOT"])
    engine = (flutter / "bin/internal/engine.version").read_text().strip()
    dart = (flutter / "bin/cache/dart-sdk/version").read_text().strip()
    if len(engine) != 40 or any(char not in "0123456789abcdef" for char in engine):
        raise ValueError("Missing exact Flutter engine revision")
    return {"checkout": subprocess.run(["git", "rev-parse", "HEAD"], cwd=REPO,
                check=True, text=True, capture_output=True).stdout.strip(),
            "actions_sha": os.environ.get("GITHUB_SHA"), "flutter": os.environ["FLUTTER_VERSION"],
            "engine": engine, "dart": dart, "android_ndk": os.environ.get("ANDROID_NDK_VERSION"),
            "tim2tox": subprocess.run(["git", "rev-parse", "HEAD:third_party/tim2tox"], cwd=REPO,
                check=True, text=True, capture_output=True).stdout.strip()}


def packages(target, arch):
    key, _, paths = app_paths(target, arch)
    symbols = REPO / "build/release-symbols" / key
    files = sorted((REPO / "dist" / target).glob("*"))
    expected = {"linux": 3, "windows": 2, "macos": 2, "android": 2, "ios": 1}[target]
    if len(files) != expected or any(not file.is_file() for file in files):
        raise ValueError("Unexpected final release package set")
    report = {"build": build_metadata(), "target": key, "packages": []}
    with tempfile.TemporaryDirectory(prefix="release symbol bytes ") as temporary:
        for package in files:
            if package.suffix == ".msi":
                report["packages"].append({"name": package.name, "sha256": sha256(package),
                    "scope": "Installed and repaired MSI native bytes are checked by test_windows_installer.ps1"})
                continue
            if target == "android":
                prefix = "base/lib" if package.suffix == ".aab" else "lib"
                entries = {f"{prefix}/{abi}/libtim2tox_ffi.so": symbols / abi / "symbols.json" for abi in ABIS}
                aot = [f"{prefix}/{abi}/libapp.so" for abi in ABIS]
                dart_dir = REPO / "build/dart-symbols" / ("android-aab" if package.suffix == ".aab" else "android-apk")
            else:
                prefix = {"linux": "opt/ditmesh/" if package.suffix in (".deb", ".rpm") else "ditmesh/",
                          "windows": "ditmesh/", "macos": "DitMesh.app/", "ios": "Payload/Runner.app/"}[target]
                entries = {prefix + entry: symbols / label / "symbols.json" for label, entry in paths.items()}
                aot = [prefix + {"linux": "lib/libapp.so", "windows": "data/app.so",
                    "macos": "Contents/Frameworks/App.framework/Versions/A/App", "ios": "Frameworks/App.framework/App"}[target]]
                dart_dir = REPO / "build/dart-symbols" / key
            data = package_bytes(package, [*entries, *aot])
            pairs = {}
            for entry, manifest in entries.items():
                binary = Path(temporary) / Path(entry).name
                binary.write_bytes(data[entry])
                pairs[entry] = verify(binary, manifest)
            report["packages"].append({"name": package.name, "sha256": sha256(package), "native": pairs,
                "dart_split_debug_info": dart_metadata(dart_dir),
                "final_dart_aot_sha256": {entry: hashlib.sha256(data[entry]).hexdigest() for entry in aot},
                "dart_scope": "Same-build split debug files and final AOT hashes; cross-format UUID equivalence is not asserted"})
    write_report(symbols / "final-packages.json", report)
    return report


def archive(output):
    xcarchive = output / "Runner.xcarchive"
    app = xcarchive / "Products/Applications/Runner.app"
    entry = plistlib.loads((app / "Info.plist").read_bytes())["CFBundleExecutable"]
    symbols = REPO / "build/release-symbols/ios-archive"
    capture(app / entry, "ios", symbols / "runner", dsym=xcarchive / "dSYMs/Runner.app.dSYM")
    result = {"build": build_metadata(), "runner": verify(app / entry, symbols / "runner/symbols.json"),
        "ffi": verify(app / "Frameworks/tim2tox_ffi.framework/tim2tox_ffi",
                      REPO / "build/native-symbols/ios/ios-device/tim2tox_ffi/symbols.json"),
        "dart_split_debug_info": dart_metadata(output / "dart-symbols"),
        "final_dart_aot_sha256": sha256(app / "Frameworks/App.framework/App")}
    write_report(symbols / "archive.json", result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("native", "prepare", "packages", "installed", "archive"))
    parser.add_argument("--target")
    parser.add_argument("--arch", default="arm64", choices=("arm64", "x86_64"))
    parser.add_argument("--root", type=Path)
    parser.add_argument("--symbols-dir", type=Path)
    args = parser.parse_args()
    if args.command == "native":
        result = native(args.target)
    elif args.command == "prepare":
        result = prepare(args.target, args.arch)
    elif args.command == "packages":
        result = packages(args.target, args.arch)
    elif args.command == "installed":
        result = installed(args.root, args.symbols_dir)
    else:
        result = archive(args.root)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
