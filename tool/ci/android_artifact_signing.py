#!/usr/bin/env python3
"""Verify final APK/AAB integrity and the selected channel's signing identity.

Play's AAB upload key and Play's installed-app signing key are separate:
https://developer.android.com/studio/publish/app-signing
JAR strict warning codes: docs.oracle.com/en/java/javase/17/docs/specs/man/jarsigner.html
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import zipfile


def run(command):
    return subprocess.run(command, capture_output=True, text=True, check=False, timeout=120)


def check_aab(path):
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or not {
                'BundleConfig.pb', 'base/manifest/AndroidManifest.xml'}.issubset(names):
            raise ValueError('AAB integrity: duplicate entries or missing bundle structure')
    result = run(['jarsigner', '-J-Duser.language=en', '-J-Duser.country=US',
                  '-verify', '-strict', str(path)])
    output = result.stdout + result.stderr
    # Code 4 includes Android's normal self-signed/untrusted chain. Do not
    # discard integrity (1), unsigned-entry (16), or usage/alias/TSA errors.
    # Reject other code-4 causes explicitly, with locale fixed above.
    bad_certificate = re.search(r'expired|not yet valid|disabled|treated as unsigned', output, re.I)
    if result.returncode not in (0, 4) or 'jar verified' not in output or bad_certificate:
        raise ValueError(f'AAB integrity verification failed: {output.strip()}')
    result = run(['keytool', '-J-Duser.language=en', '-J-Duser.country=US',
                  '-printcert', '-jarfile', str(path)])
    if result.returncode:
        raise ValueError('Cannot read verified AAB signing certificate')
    return result.stdout


def digest(value):
    normalized = value.replace(':', '').strip().lower()
    if not re.fullmatch('[0-9a-f]{64}', normalized):
        raise ValueError('Expected a SHA-256 certificate fingerprint (64 hex digits)')
    return normalized


def check_reports(apk, aab, distribution, expected):
    if distribution and re.search(r'CN\s*=\s*Android\s*Debug\b', apk + aab, re.I):
        raise ValueError('Android debug certificate is forbidden for distribution/tags')
    apk_digests = {digest(value) for value in re.findall(
        r'certificate SHA-256 digest:\s*([0-9a-fA-F:]+)', apk)}
    # One upload signer is the current DitMesh release contract. A rotated or
    # multi-signer channel needs explicit lineage handling, never a guessed key.
    aab_digests = re.findall(r'SHA256:\s*([0-9a-fA-F:]+)', aab)
    if len(apk_digests) != 1 or len(aab_digests) != 1:
        raise ValueError('Expected exactly one APK signer and one AAB upload certificate')
    actual = next(iter(apk_digests))
    if actual != digest(aab_digests[0]):
        raise ValueError('APK signer and AAB upload certificate do not match')
    if distribution and (not expected or actual != digest(expected)):
        raise ValueError('Distribution/tag certificate must match DITMESH_ANDROID_CERT_SHA256')
    return actual


def find_build_tool(name):
    direct = shutil.which(name)
    if direct:
        return direct
    root = os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME')
    if not root:
        raise ValueError(f'ANDROID_HOME/ANDROID_SDK_ROOT or {name} on PATH is required')
    candidates = list((Path(root) / 'build-tools').glob(f'*/{name}'))
    candidates = [path for path in candidates if re.fullmatch(r'\d+(?:\.\d+)+', path.parent.name)]
    if not candidates:
        raise ValueError(f'No stable Android build-tools {name} found')
    return str(max(candidates, key=lambda path: tuple(map(int, path.parent.name.split('.')))))


def find_apksigner():
    return find_build_tool('apksigner')


def check_apk(path):
    result = run([find_apksigner(), 'verify', '--verbose', '--print-certs', str(path)])
    if result.returncode:
        raise ValueError(f'APK integrity verification failed: {result.stderr.strip()}')
    return result.stdout


def check_identity(badging, version, build, distribution):
    package = re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging, re.M)
    if not package or (package[1], package[2], package[3]) != ('icu.agentx.ditmesh', str(build), version):
        raise ValueError('Final APK application ID/version/build do not match release source')
    if distribution and 'application-debuggable' in badging:
        raise ValueError('Distribution/tag APK is debuggable')
    return {'application_id': package[1], 'version': package[3], 'build': package[2]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('aab', type=Path)
    parser.add_argument('--distribution', action='store_true')
    parser.add_argument('--version', required=True)
    parser.add_argument('--build-number', required=True)
    args = parser.parse_args()
    actual = check_reports(check_apk(args.apk), check_aab(args.aab), args.distribution,
                           os.environ.get('DITMESH_ANDROID_CERT_SHA256', ''))
    badging = run([find_build_tool('aapt2'), 'dump', 'badging', str(args.apk)])
    if badging.returncode:
        raise ValueError('Cannot inspect final APK manifest with aapt2')
    identity = check_identity(badging.stdout, args.version, args.build_number, args.distribution)
    print(json.dumps({'apk_and_upload_certificate_sha256': actual,
                      'apk_identity': identity,
                      'mode': 'distribution-signing' if args.distribution else 'validation',
                      'play_delivered_certificate': 'not evaluated; owner must verify in Play Console'}))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, zipfile.BadZipFile, subprocess.SubprocessError) as error:
        print(f'Android artifact signing: {error}', file=sys.stderr)
        sys.exit(1)
