#!/usr/bin/env python3
"""Apply reviewed DitMesh native overlays without modifying the pinned checkout."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

OVERLAYS = Path(__file__).resolve().parent / "tim2tox-overlays"
STAMP = ".ditmesh-native-overlay-sha256"
IGNORED = {".git", ".dart_tool", "build", "__pycache__"}


def ignored(directory, names):
    return [name for name in names if name in IGNORED or name.endswith(".pyc")]


def source_fingerprint(source, patches):
    digest = hashlib.sha256(Path(__file__).read_bytes())
    for directory, subdirs, files in os.walk(source):
        subdirs[:] = sorted(name for name in subdirs if name not in IGNORED)
        for name in sorted(files):
            if name in IGNORED or name.endswith(".pyc"):
                continue
            path = Path(directory) / name
            digest.update(path.relative_to(source).as_posix().encode())
            digest.update(b"\0")
            digest.update(hashlib.sha256(path.read_bytes()).digest())
    for patch in patches:
        digest.update(patch.name.encode())
        digest.update(patch.read_bytes())
    return digest.hexdigest()


def prepare(source, destination):
    source = source.resolve(strict=True)
    destination = destination.resolve()
    if source == destination or source in destination.parents or destination in source.parents:
        raise ValueError("The overlay destination must not overlap the upstream checkout")
    patches = sorted(OVERLAYS.glob("*.patch"))
    if not patches:
        raise ValueError("No reviewed native overlay patches found")
    fingerprint = source_fingerprint(source, patches)
    stamp = destination / STAMP
    if stamp.exists() and stamp.read_text().strip() == fingerprint:
        return
    if destination.exists() and not stamp.exists():
        raise ValueError(f"Refusing to replace an unmanaged source directory: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".tim2tox-overlay-", dir=destination.parent) as root:
        staged = Path(root) / "tim2tox"
        shutil.copytree(source, staged, symlinks=True, ignore=ignored)
        for patch in patches:
            result = subprocess.run(
                ["git", "apply", "--unsafe-paths", f"--directory={staged.as_posix()}",
                 str(patch)],
                capture_output=True, text=True, check=False,
            )
            if result.returncode:
                raise ValueError(f"Native overlay patch {patch.name} failed: {result.stderr.strip()}")
        (staged / STAMP).write_text(fingerprint + "\n")
        if destination.exists():
            shutil.rmtree(destination)
        staged.replace(destination)


def main():
    if len(sys.argv) != 3:
        raise ValueError("Usage: prepare_native_source.py <upstream-source> <staged-source>")
    prepare(Path(sys.argv[1]), Path(sys.argv[2]))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"Native source overlay failed: {error}", file=sys.stderr)
        sys.exit(1)
