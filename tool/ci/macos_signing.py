#!/usr/bin/env python3
"""Seal validation bundles inside out after staging; never notarize/upload.

Ad-hoc signing proves integrity and entitlements, not developer identity or
Gatekeeper acceptance. Developer ID/Mac App Store release paths remain blocked.
https://developer.apple.com/documentation/technotes/tn2206-macos-code-signing-in-depth
"""
import argparse
import json
from pathlib import Path
import plistlib
import subprocess
import sys

from macos_runtime import MACHO_MAGICS


def code_paths(app):
    app = Path(app).resolve()
    binaries, containers, seen = [], [], set()
    for path in app.rglob('*'):
        resolved = path.resolve()
        if not resolved.is_relative_to(app):
            raise ValueError(f'Code path resolves outside bundle: {path}')
        if path.is_symlink() and not path.exists():
            raise ValueError(f'Dangling code symlink: {path}')
        if path.is_dir() and not path.is_symlink() and path.suffix in ('.framework', '.app', '.xpc'):
            containers.append(path)
        if not path.is_file() or resolved in seen:
            continue
        seen.add(resolved)
        with path.open('rb') as stream:
            if stream.read(4) in MACHO_MAGICS:
                binaries.append(resolved)
    if not binaries:
        raise ValueError('No Mach-O code to sign/verify')
    return sorted(binaries, key=lambda p: (-len(p.parts), str(p))), sorted(
        containers, key=lambda p: (-len(p.parts), str(p)))


def checked(command):
    result = subprocess.run(command, capture_output=True, text=True, check=False, timeout=120)
    if result.returncode:
        raise ValueError(f'macOS signature command failed: {result.stderr.strip()}')
    return result.stdout


def verify(app):
    app = Path(app).resolve()
    binaries, containers = code_paths(app)
    checked(['codesign', '--verify', '--deep', '--strict', str(app)])
    for path in [*binaries, *containers, app]:
        checked(['codesign', '--verify', '--strict', str(path)])
        output = checked(['codesign', '--display', '--entitlements', '-', '--xml', str(path)])
        entitlements = plistlib.loads(output.encode()) if output.strip() else {}
        if entitlements.get('com.apple.security.get-task-allow'):
            raise ValueError(f'{path}: get-task-allow is forbidden in release artifacts')
    return {'signed_code': len(binaries), 'mode': 'ad-hoc validation; no distribution identity asserted'}


def seal(app, entitlements):
    app = Path(app).resolve()
    with Path(entitlements).open('rb') as stream:
        if plistlib.load(stream).get('com.apple.security.get-task-allow'):
            raise ValueError('Release source entitlements enable get-task-allow')
    binaries, containers = code_paths(app)
    # DitMesh currently has no nested app/XPC executable requiring its own
    # entitlements. Refuse a future helper rather than silently stripping them.
    if any(path.suffix in ('.app', '.xpc') for path in containers):
        raise ValueError('Nested helper needs an explicit entitlement/signing policy')
    for path in [*binaries, *containers]:
        checked(['codesign', '--force', '--sign', '-', '--timestamp=none', str(path)])
    checked(['codesign', '--force', '--sign', '-', '--timestamp=none',
             '--entitlements', str(entitlements), str(app)])
    return verify(app)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('--seal-with-entitlements', type=Path)
    args = parser.parse_args()
    result = seal(args.app, args.seal_with_entitlements) if args.seal_with_entitlements else verify(args.app)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f'macOS signing: {error}', file=sys.stderr)
        sys.exit(1)
