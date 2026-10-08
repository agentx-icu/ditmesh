#!/usr/bin/env python3
"""Reject a macOS app whose embedded binaries require a newer OS than advertised.

Apple load-command definitions:
https://github.com/apple-oss-distributions/xnu/blob/main/EXTERNAL_HEADERS/mach-o/loader.h
"""
import json
from pathlib import Path
import plistlib
import re
import subprocess
import sys

MACHO_MAGICS = {
    bytes.fromhex(value) for value in
    ("feedface", "cefaedfe", "feedfacf", "cffaedfe",
     "cafebabe", "bebafeca", "cafebabf", "bfbafeca")
}


def version(value):
    if not isinstance(value, str) or not re.fullmatch(r"\d+(?:\.\d+){0,2}", value):
        raise ValueError(f"Invalid macOS minimum version: {value!r}")
    parts = tuple(map(int, value.split(".")))
    return parts + (0,) * (3 - len(parts))


def display(value):
    return ".".join(map(str, value))


def parse_versions(output):
    """Read every architecture's minimum, without mistaking SDK/tool versions."""
    slices = re.split(r"(?m)^.+ \(architecture [^)]+\):\s*$", output)
    if len(slices) > 1:
        return [minimum for text in slices[1:] for minimum in parse_versions(text)]
    minima = []
    for block in re.split(r"(?m)^\s*Load command \d+\s*$", output):
        if re.search(r"(?m)^\s*cmd LC_BUILD_VERSION\s*$", block):
            platform = re.search(r"(?m)^\s*platform (\S+)\s*$", block)
            if platform is None or platform[1].lower() not in ("1", "macos"):
                raise ValueError("Embedded binary has a non-macOS build platform")
            minimum = re.search(r"(?m)^\s*minos (\S+)\s*$", block)
        elif re.search(r"(?m)^\s*cmd LC_VERSION_MIN_MACOSX\s*$", block):
            minimum = re.search(r"(?m)^\s*version (\S+)\s*$", block)
        else:
            continue
        if minimum is None:
            raise ValueError("Embedded binary has an incomplete minimum-OS command")
        minima.append(version(minimum[1]))
    if not minima:
        raise ValueError("Embedded Mach-O has no macOS minimum-OS declaration")
    return minima


def inspect_binary(path):
    result = subprocess.run(["otool", "-arch", "all", "-l", str(path)], capture_output=True,
                            text=True, check=False, timeout=30)
    if result.returncode:
        raise ValueError(f"Cannot inspect Mach-O {path}: {result.stderr.strip()}")
    return result.stdout


def check_bundle(app, inspect=inspect_binary):
    app = Path(app).resolve()
    with (app / "Contents/Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    floor = version(info.get("LSMinimumSystemVersion"))
    binaries = []
    violations = []
    seen = set()
    for path in sorted(app.rglob("*")):
        resolved = path.resolve()
        if not resolved.is_relative_to(app):
            raise ValueError(f"Bundle path resolves outside the application: {path}")
        if not path.is_file():
            continue
        if resolved in seen:
            continue
        seen.add(resolved)
        with resolved.open("rb") as stream:
            if stream.read(4) not in MACHO_MAGICS:
                continue
        minima = parse_versions(inspect(resolved))
        required = max(minima)
        relative = str(resolved.relative_to(app))
        if required > floor:
            violations.append(f"{relative} requires macOS {display(required)}; "
                              f"application advertises {display(floor)}")
        binaries.append({"path": relative,
                         "architecture_minima": [display(v) for v in minima]})
    if not binaries:
        raise ValueError("No Mach-O runtime binaries found in application")
    if violations:
        raise ValueError("; ".join(violations))
    return {"app_minimum": display(floor), "binaries": binaries}


def main():
    if len(sys.argv) != 2:
        raise ValueError("Usage: macos_runtime.py <application.app>")
    print(json.dumps(check_bundle(sys.argv[1]), indent=2))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"macOS runtime compatibility: {error}", file=sys.stderr)
        sys.exit(1)
