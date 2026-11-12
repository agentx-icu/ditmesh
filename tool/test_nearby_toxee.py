#!/usr/bin/env python3
"""Run DitMesh's real backend against Toxee's production nearby/SDK worker.

Discovery uses isolated test profiles and fixed synthetic positions. An
explicit private OS snapshot can additionally exercise encrypted C2C messages.
Native sockets transport all discovery, intent, friend and location payloads.
"""

import argparse
import atexit
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import threading
import time

from nearby_real_location import load_snapshot, real_toxee_worker, redact_log


def stop(process):
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
    except ProcessLookupError:
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--toxee', type=Path, required=True)
    parser.add_argument('--toxee-harness', type=Path)
    parser.add_argument('--ditmesh-lib', type=Path, required=True)
    parser.add_argument('--toxee-lib', type=Path, required=True)
    parser.add_argument('--flutter', default=shutil.which('flutter'))
    parser.add_argument('--output', type=Path)
    parser.add_argument('--timeout', type=int, default=420)
    parser.add_argument('--real-location-file', type=Path,
                        help='Private fresh OS snapshot; verify encrypted C2C only')
    args = parser.parse_args()
    if not args.flutter:
        parser.error('Flutter is not on PATH; pass --flutter')
    if args.timeout <= 0:
        parser.error('--timeout must be positive')
    snapshot = None
    if args.real_location_file:
        try:
            snapshot = load_snapshot(args.real_location_file)
        except (ValueError, KeyError, TypeError, OSError):
            parser.error('Invalid or stale real OS snapshot; acquire a fresh one')
    project = Path(__file__).resolve().parents[1]
    output = (args.output or Path(tempfile.mkdtemp(prefix='ditmesh-toxee-interop-'))).resolve()
    output.mkdir(parents=True, exist_ok=True)
    exchange = Path(tempfile.mkdtemp(prefix='exchange-', dir=output)).resolve()
    if snapshot:
        # Also clean private profiles on an exception/interrupt before the
        # ordinary result path. This directory was created by this run.
        atexit.register(shutil.rmtree, exchange, ignore_errors=True)
    private_snapshot = None
    if snapshot:
        private_snapshot = exchange / 'real-location.json'
        private_snapshot.write_text(json.dumps(snapshot))
        private_snapshot.chmod(0o600)
    libs = {'alice': args.ditmesh_lib.resolve(strict=True),
            'bob': args.toxee_lib.resolve(strict=True)}
    projects = {'alice': project / 'packages/ditmesh_chat',
                'bob': (args.toxee_harness or args.toxee).resolve()}
    tests = {'alice': project / 'packages/ditmesh_chat/test/native_toxee_interop_test.dart',
             'bob': args.toxee.resolve() / 'test/native/location_network_peer_test.dart'}
    # Both applications normally enable IPv6. The existing Toxee worker
    # forces IPv4 only; that lets macOS bind it to the same UDP port as the
    # IPv6 peer, so align this test-only network option in an isolated copy.
    original_bob_test = tests['bob']
    bob_source = original_bob_test.read_text().replace('ipv6Enabled: false', 'ipv6Enabled: true')
    # A native second-cell join can miss the immediate throttled presence.
    # Allow two production 60 s refresh ticks plus scheduling time on both
    # workers; changing the presence cadence would hide that recovery path.
    bob_source = bob_source.replace('Duration(seconds: 120)', 'Duration(seconds: 180)')
    bob_source = bob_source.replace("import '../../third_party/", "import '" + (args.toxee.resolve() / 'third_party').as_uri() + '/')
    if snapshot:
        bob_source = real_toxee_worker(bob_source)
    tests['bob'] = output / 'toxee_peer_test.dart'
    tests['bob'].write_text(bob_source)
    processes, logs, readers = {}, {}, []
    seen, timed_out = set(), False
    print(f'Artifacts: {output}', flush=True)
    try:
        for role in ('alice', 'bob'):
            env = os.environ.copy()
            if private_snapshot:
                runtime = exchange / f'{role}-runtime'
                runtime.mkdir(mode=0o700)
                env['TMPDIR'] = str(runtime) + '/'
                env['DITMESH_REAL_LOCATION_FILE'] = str(private_snapshot)
                env['TOXEE_LOCATION_REAL_FILE'] = str(private_snapshot)
            if role == 'alice':
                env.update(DITMESH_TOXEE_EXCHANGE=str(exchange), TIM2TOX_FFI_LIB=str(libs[role]))
            else:
                env.update(TOXEE_LOCATION_PEER_ROLE=role,
                           TOXEE_LOCATION_PEER_EXCHANGE=str(exchange),
                           TOXEE_LOCATION_NATIVE_LIB=str(libs[role]),
                           RUN_VIRTUAL='0', PARALLEL_WORKERS='2')
            logs[role] = (output / f'{role}.log').open('w')
            processes[role] = subprocess.Popen(
                [args.flutter, 'test', '--no-pub', str(tests[role]), '--reporter', 'expanded'],
                cwd=projects[role], env=env, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, start_new_session=True,
                text=True, encoding='utf-8', errors='replace', bufsize=1)
            def pump(process=processes[role], log=logs[role]):
                for line in process.stdout:
                    log.write(redact_log(line) if snapshot else line)
                    log.flush()
            reader = threading.Thread(target=pump, daemon=True)
            reader.start()
            readers.append(reader)
        deadline = time.monotonic() + args.timeout
        while any(process.poll() is None for process in processes.values()):
            for marker in sorted(exchange.glob('*.json')):
                if marker.name not in seen:
                    seen.add(marker.name)
                    print(f'Observed phase: {marker.stem}', flush=True)
            if time.monotonic() > deadline:
                timed_out = True
                break
            if any(process.poll() not in (None, 0) for process in processes.values()):
                break
            time.sleep(.25)
    finally:
        for process in processes.values():
            stop(process)
        for reader in readers:
            reader.join(timeout=10)
        for log in logs.values():
            log.close()
    codes = {role: process.returncode for role, process in processes.items()}
    passed = not timed_out and len(codes) == 2 and all(code == 0 for code in codes.values())
    peers = {}
    required = ('endpoint', 'discovered', 'friend-connected', 'location-received',
                'group-ready', 'group-location-sent', 'group-location-received', 'passed')
    if snapshot:
        required = ('endpoint', 'discovered', 'friend-connected',
                    'location-received', 'passed')
    for role in ('alice', 'bob'):
        peers[role] = {}
        for phase in required:
            file = exchange / f'{role}.{phase}.json'
            if not file.exists():
                passed = False
                continue
            peers[role][phase] = json.loads(file.read_text())
    if passed:
        passed = peers['alice']['endpoint']['pid'] != peers['bob']['endpoint']['pid']
        passed = passed and all(p['passed']['nativePackets'] > 0 for p in peers.values())
        if snapshot:
            passed = passed and all(p['location-received'].get('coordinatesMatched')
                                    is True for p in peers.values())
    result = {'passed': passed, 'exitCodes': codes, 'timedOut': timed_out,
              'transport': 'Real native Tox UDP between independent DitMesh and Toxee processes',
              'locationSource': ('Real OS snapshot for encrypted C2C; synthetic discovery'
                                 if snapshot else 'Fixed synthetic coordinates; no OS location claim'),
              'toxeeWorkerSource': str(original_bob_test),
              'toxeeWorkerSourceSha256': hashlib.sha256(original_bob_test.read_bytes()).hexdigest(),
              'executedToxeeWorkerSha256': hashlib.sha256(tests['bob'].read_bytes()).hexdigest(),
              'toxeeWorkerNetworkOverrides': {'ipv6Enabled': True},
              'toxeeWorkerWaitTimeoutSeconds': 180,
              'exchange': str(exchange), 'peers': peers,
              'libraries': {role: {'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
                            for role, path in libs.items()}}
    if snapshot:
        result['osSnapshot'] = {'capturedAtUtc': snapshot['capturedAtUtc'],
                                'accuracyM': snapshot['accuracyM'],
                                'coordinatesRecorded': False}
        shutil.rmtree(exchange)
        result['privateTestDataRemoved'] = not exchange.exists()
    (output / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(f'{"PASS" if passed else "FAIL"}: {codes}; evidence {output}', flush=True)
    if not passed:
        for role in ('alice', 'bob'):
            print(f'{role} log tail:\n' + '\n'.join((output / f'{role}.log').read_text(errors='replace').splitlines()[-25:]))
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
