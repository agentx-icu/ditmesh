#!/usr/bin/env python3
"""Hosted-only native I/O probe with the exact final EXE's embedded manifest."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

from windows_manifest import WS2016, check_executable


def run(command, log, timeout=180):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, encoding='utf-8', errors='replace')
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        # Only this helper's owned compiler/probe process tree, never app processes.
        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                       check=False, capture_output=True, timeout=20)
        output, _ = process.communicate(timeout=20)
        log.write_text(output, encoding='utf-8')
        raise ValueError('Native path probe command timed out')
    log.write_text(output, encoding='utf-8')
    return process.returncode, output


def fixture_project(directory, manifest, negative_manifest, ffi):
    probe = Path(__file__).with_suffix('.cpp').resolve()
    (directory / 'CMakeLists.txt').write_text(f'''cmake_minimum_required(VERSION 3.16)
project(ditmesh_path_probe LANGUAGES CXX)
if(NOT MSVC)
  message(FATAL_ERROR "The path probe requires the same Windows MSVC CRT family")
endif()
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
foreach(target IN ITEMS positive negative)
  if(target STREQUAL "positive")
    set(manifest "{manifest.as_posix()}")
  else()
    set(manifest "{negative_manifest.as_posix()}")
  endif()
  add_executable(${{target}} "{probe.as_posix()}" "{ffi.as_posix()}" "${{manifest}}")
  target_include_directories(${{target}} PRIVATE "{ffi.parent.as_posix()}")
  target_compile_options(${{target}} PRIVATE /utf-8)
endforeach()
''', encoding='utf-8')


def probe(executable, evidence):
    if (os.name != 'nt' or os.environ.get('GITHUB_ACTIONS') != 'true'
            or os.environ.get('RUNNER_ENVIRONMENT') != 'github-hosted'):
        raise ValueError('Native path probe is restricted to disposable GitHub-hosted Windows runners')
    import winreg
    evidence.mkdir(parents=True, exist_ok=True)
    report = {'outcome': 'failed', 'scope': 'Manifest/native I/O prerequisite, not an installed FFI flow'}
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r'SYSTEM\CurrentControlSet\Control\FileSystem') as key:
            policy = winreg.QueryValueEx(key, 'LongPathsEnabled')[0]
        report['LongPathsEnabled'] = policy
        if policy != 1:
            raise ValueError('The existing host LongPathsEnabled policy must be 1; this test never changes it')
        repo = Path(__file__).resolve().parents[2]
        ffi = repo / 'third_party/tim2tox/ffi/file_io_compat.cpp'
        report['ffi_source_sha256'] = hashlib.sha256(ffi.read_bytes()).hexdigest()
        with tempfile.TemporaryDirectory(prefix='DitMesh native path ', dir=os.environ['RUNNER_TEMP']) as temporary:
            root = Path(temporary)
            source = root / 'source'
            source.mkdir()
            manifest = source / 'positive.manifest'
            report['final_exe'] = check_executable(executable, manifest)
            tree = ET.fromstring(manifest.read_bytes())
            node = tree.find(f'.//{{{WS2016}}}longPathAware')
            node.text = 'false'
            negative_manifest = source / 'negative.manifest'
            negative_manifest.write_bytes(ET.tostring(tree, encoding='utf-8', xml_declaration=True))
            fixture_project(source, manifest, negative_manifest, ffi)
            build = root / 'build'
            for command, label in ((['cmake', '-S', str(source), '-B', str(build), '-A', 'x64'], 'configure'),
                                   (['cmake', '--build', str(build), '--config', 'Release'], 'build')):
                code, _ = run(command, evidence / (label + '.log'), timeout=300)
                if code != 0:
                    raise ValueError(f'Native path probe {label} failed: {code}')
            positive, negative = build / 'Release/positive.exe', build / 'Release/negative.exe'
            report['probe_exe'] = check_executable(positive)
            try:
                check_executable(negative)
            except ValueError as error:
                if 'longPathAware' not in str(error):
                    raise
            else:
                raise ValueError('Negative embedded manifest was incorrectly accepted')
            report['negative_manifest_rejected'] = True
            for label, exe in (('positive', positive), ('negative', negative)):
                data = root / (label + ' private data')
                data.mkdir()
                code, output = run([str(exe), str(data)], evidence / (label + '.log'), timeout=30)
                if label == 'positive':
                    if code != 0:
                        raise ValueError(f'Long Unicode native I/O failed: {code}')
                    report['native_io'] = json.loads(output)
                    if report['native_io'].get('outcome') != 'passed' or report['native_io'].get('utf16_path_length', 0) <= 260:
                        raise ValueError('Native path probe did not verify a long path')
                elif code != 1 or 'CreateDirectoryW failure code=206 ' not in output:
                    raise ValueError('Without the opt-in, the same native probe must fail at the long-path boundary')
            report['negative_native_io_rejected'] = True
        report['outcome'] = 'passed'
    except Exception as error:
        report['failure_type'] = type(error).__name__
        raise
    finally:
        (evidence / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--evidence-dir', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(probe(args.exe.resolve(), args.evidence_dir.resolve()), indent=2))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError, ET.ParseError) as error:
        print(f'Windows native path probe: {error}', file=sys.stderr)
        sys.exit(1)
