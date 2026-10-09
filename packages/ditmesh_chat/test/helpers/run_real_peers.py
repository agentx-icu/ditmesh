#!/usr/bin/env python3
"""Run two isolated real Tox peers, retaining logs and encrypted test profiles.

Example from the workspace root (dependencies must already be resolved):
  python3 packages/ditmesh_chat/test/helpers/run_real_peers.py \
      --library build/native/macos-arm64/libtim2tox_ffi.dylib

Only endpoint coordinates and synchronization markers use shared files. Chat
payloads are exchanged and verified by the production native backend.
"""

import argparse
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time


def stop_group(process, sig):
    try:
        os.killpg(process.pid, sig)
    except (ProcessLookupError, PermissionError):
        # It finished between poll() and signalling (macOS answers EPERM
        # for a process group whose leader has already exited).
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", required=True, type=Path)
    parser.add_argument("--flutter", default=shutil.which("flutter"))
    parser.add_argument("--timeout", default=780, type=int)
    args = parser.parse_args()
    if os.name != "posix":
        parser.error("This host harness requires POSIX process groups (macOS/Linux)")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    library = args.library.resolve(strict=True)
    if not args.flutter:
        parser.error("Flutter is not on PATH; pass --flutter")
    package = Path(__file__).resolve().parents[2]
    root = Path(tempfile.mkdtemp(prefix="ditmesh_real_peers_"))
    processes = []
    logs = []
    print(f"Real-peer artifacts: {root}", flush=True)
    try:
        for role in ("alice", "bob"):
            log = (root / f"{role}.test.log").open("w")
            logs.append(log)
            env = dict(os.environ, DITMESH_REAL_PEER_ROLE=role,
                       DITMESH_REAL_PEER_ROOT=str(root),
                       TIM2TOX_FFI_LIB=str(library))
            processes.append(subprocess.Popen(
                [args.flutter, "test", "--no-pub", "test/native_two_peer_test.dart",
                 "--reporter", "expanded"], cwd=package, env=env,
                stdout=log, stderr=subprocess.STDOUT, start_new_session=True))
        deadline = time.monotonic() + args.timeout
        while any(process.poll() is None for process in processes):
            if time.monotonic() >= deadline:
                raise RuntimeError(f"Peer harness exceeded {args.timeout}s")
            if any(process.poll() not in (None, 0) for process in processes):
                raise RuntimeError("A peer failed; inspect its test/backend logs")
            time.sleep(0.25)
        if any(process.returncode != 0 for process in processes):
            raise RuntimeError("A peer failed; inspect its test/backend logs")
        if not all((root / f"{role}.complete").exists() for role in ("alice", "bob")):
            raise RuntimeError("Workers exited without completing the real-peer scenario")
        print("PASS: real DM, NGC, encrypted restart, durable queue, NGC rejoin "
              "and rejoinGroup of a held group", flush=True)
        return 0
    except (RuntimeError, KeyboardInterrupt) as error:
        print(f"FAIL: {error}\nEvidence retained at {root}", flush=True)
        return 1
    finally:
        for process in processes:
            if process.poll() is None:
                stop_group(process, signal.SIGTERM)
        end = time.monotonic() + 10
        for process in processes:
            try:
                process.wait(timeout=max(0.1, end - time.monotonic()))
            except subprocess.TimeoutExpired:
                stop_group(process, signal.SIGKILL)
                process.wait()
        for log in logs:
            log.close()


if __name__ == "__main__":
    raise SystemExit(main())
