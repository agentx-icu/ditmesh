"""Exact-PID hosted-runner diagnostic, never a lifecycle pass/fail oracle.

The caller must first verify Process.MainModule.FileName and StartTime against
the fresh smoke launch using Get-ExactProcessCrashContext. No debugger install,
target calls, writes, environment inspection, locals or memory dump commands.
"""
from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
import ntpath
import os
from pathlib import Path
import queue
import re
import subprocess
import sys
import threading
import time


COMMANDS = r"""set pagination off
set confirm off
set print frame-arguments none
set print entry-values no
set print frame-info location-and-address
handle all stop print pass
handle SIGSEGV stop print pass
handle SIGABRT stop print pass
handle SIGILL stop print pass
handle SIGFPE stop print pass
echo GDB_TRACE_READY\n
while $_isvoid($_exitcode) && $_isvoid($_exitsignal)
  continue
  if $_isvoid($_exitcode) && $_isvoid($_exitsignal)
    echo GDB_TRACE_STOP\n
    backtrace -no-filters -frame-arguments none -entry-values no -frame-info location-and-address 48
    thread apply all -c backtrace -no-filters -frame-arguments none -entry-values no -frame-info location-and-address 16
    info sharedlibrary
  end
end
echo GDB_TRACE_TARGET_EXITED\n
quit
"""


def scoped_line(line: str) -> str | None:
    """Never publish raw debugger/app messages or unfiltered thread text."""
    line = line.strip()
    if line in {"GDB_TRACE_READY", "GDB_TRACE_STOP", "GDB_TRACE_TARGET_EXITED"}:
        return line
    signal = re.search(r"received signal (SIG[A-Z0-9]+)\b", line)
    if signal:
        return "signal " + signal.group(1)
    if re.match(r"^#\d+\s+", line):
        # All argument printing is disabled before attach and again per bt.
        # This is a stack frame, not `info locals`, raw stack data or source text.
        return line[:2048]
    module = re.match(r"^(0x[0-9a-f]+)\s+(0x[0-9a-f]+)\s+(?:Yes(?:\s+\(\*\))?|No)\s+(.+)$", line, re.I)
    if module:
        return f"module {module[1]} {module[2]} {ntpath.basename(module[3])}"
    thread = re.match(r"^Thread (\d+) \(Thread ([0-9a-fx.]+)\):$", line, re.I)
    if thread:
        return f"thread index={thread[1]} id={thread[2]}"
    exited = re.match(r"^\[Inferior \d+ \(process (\d+)\) exited with code ([0-9a-fx]+)\]$", line, re.I)
    if exited:
        return f"target_exit pid={exited[1]} gdb_code={exited[2]}"
    # Native GDB reports an unknown Windows exception as a warning; extract only
    # the exception code, never arbitrary OutputDebugString warning contents.
    unknown = re.match(r"^(?:warning: |gdb: )\bunknown target exception (0x[0-9a-f]+)\b", line, re.I)
    if unknown:
        return "windows_exception " + unknown[1].lower()
    return None


def assert_fresh_target(pid: int, executable: Path, started_filetime: int) -> None:
    """Read-only process identity check independent of the PowerShell caller."""
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel32.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    kernel32.OpenProcess.restype = wintypes.HANDLE
    kernel32.QueryFullProcessImageNameW.argtypes = (wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD))
    kernel32.QueryFullProcessImageNameW.restype = wintypes.BOOL
    kernel32.GetProcessTimes.argtypes = (wintypes.HANDLE,) + (ctypes.POINTER(wintypes.FILETIME),) * 4
    kernel32.GetProcessTimes.restype = wintypes.BOOL
    kernel32.GetExitCodeProcess.argtypes = (wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD))
    kernel32.GetExitCodeProcess.restype = wintypes.BOOL
    kernel32.CloseHandle.argtypes = (wintypes.HANDLE,)
    kernel32.CloseHandle.restype = wintypes.BOOL
    handle = kernel32.OpenProcess(0x1000, False, pid)  # QUERY_LIMITED_INFORMATION
    if not handle:
        raise OSError(ctypes.get_last_error(), "Cannot query the exact test process")
    try:
        size = wintypes.DWORD(32768)
        image = ctypes.create_unicode_buffer(size.value)
        if not kernel32.QueryFullProcessImageNameW(handle, 0, image, ctypes.byref(size)):
            raise OSError(ctypes.get_last_error(), "Cannot read the exact process image")
        if os.path.normcase(os.path.abspath(image.value)) != os.path.normcase(str(executable.resolve(strict=True))):
            raise ValueError("Trace target is not the exact installed executable")
        creation, exited, kernel, user = (wintypes.FILETIME() for _ in range(4))
        if not kernel32.GetProcessTimes(handle, ctypes.byref(creation), ctypes.byref(exited), ctypes.byref(kernel), ctypes.byref(user)):
            raise OSError(ctypes.get_last_error(), "Cannot read the exact process start")
        actual_creation = (creation.dwHighDateTime << 32) | creation.dwLowDateTime
        if abs(actual_creation - started_filetime) > 10_000_000:
            raise ValueError("Trace target start differs from the fresh smoke launch")
        exit_code = wintypes.DWORD()
        if not kernel32.GetExitCodeProcess(handle, ctypes.byref(exit_code)) or exit_code.value != 259:
            raise ValueError("Trace target already exited")
    finally:
        kernel32.CloseHandle(handle)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pid", required=True, type=int)
    parser.add_argument("--exe", required=True, type=Path)
    parser.add_argument("--started-filetime-utc", required=True, type=int)
    parser.add_argument("--evidence-dir", required=True, type=Path)
    parser.add_argument("--stage", required=True, choices=("installed", "repaired"))
    args = parser.parse_args()
    if sys.platform != "win32" or os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("RUNNER_ENVIRONMENT") != "github-hosted":
        raise SystemExit("Trace is restricted to disposable GitHub-hosted Windows")
    if args.pid <= 0:
        raise SystemExit("Expected the exact positive fresh smoke PID")
    evidence = args.evidence_dir.resolve(strict=True)
    metadata_path = evidence / f"{args.stage}-gdb.json"
    ready_path = evidence / f"{args.stage}-gdb.ready"
    trace_path = evidence / f"{args.stage}-gdb-trace.txt"
    command_path = evidence / f"{args.stage}-gdb-commands.txt"
    if ready_path.exists():
        raise SystemExit("Refusing stale diagnostic readiness marker")
    report: dict = {"pid": args.pid, "status": "unavailable", "downloaded": False}
    # Exact known hosted-toolchain locations; no repo/PATH-local executable.
    debugger = next((p for p in (Path(r"C:\mingw64\bin\gdb.exe"), Path(r"C:\msys64\mingw64\bin\gdb.exe")) if p.is_file()), None)
    if debugger is None:
        metadata_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        return 2
    report.update(debugger=str(debugger), debugger_sha256=hashlib.sha256(debugger.read_bytes()).hexdigest())
    command_path.write_text(COMMANDS, encoding="ascii")
    command = [str(debugger), "-nx", "-nh", "--quiet", "--batch"]
    # These execute before -p so the synthetic attach stop cannot print args or
    # auto-load scripts; symbols are local only and no debuginfod download runs.
    for setting in ("set auto-load off", "set debuginfod enabled off", "set print frame-arguments none", "set print entry-values no", "set print frame-info location-and-address"):
        command.extend(("-iex", setting))
    command.extend(("-p", str(args.pid), "-x", str(command_path)))
    process: subprocess.Popen | None = None
    lines: queue.Queue[str | None] = queue.Queue()
    try:
        assert_fresh_target(args.pid, args.exe, args.started_filetime_utc)
        process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace", creationflags=subprocess.CREATE_NO_WINDOW)
        assert process.stdout is not None

        def read_output() -> None:
            try:
                for line in process.stdout:
                    lines.put(line)
            finally:
                lines.put(None)

        threading.Thread(target=read_output, daemon=True).start()
        report["status"] = "attaching"
        deadline = time.monotonic() + 90
        with trace_path.open("w", encoding="utf-8") as trace:
            while True:
                if time.monotonic() >= deadline:
                    raise TimeoutError("Native diagnostic timed out")
                try:
                    line = lines.get(timeout=0.1)
                except queue.Empty:
                    continue
                if line is None:
                    break
                selected = scoped_line(line)
                if selected is None:
                    continue
                trace.write(selected + "\n")
                trace.flush()
                if selected == "GDB_TRACE_READY":
                    ready_path.write_text("attached\n", encoding="ascii")
                    report["status"] = "attached"
                elif selected == "GDB_TRACE_TARGET_EXITED":
                    report["status"] = "target_exited"
        report["debugger_exit_code"] = process.wait(timeout=5)
        if report["status"] != "target_exited":
            report["status"] = "incomplete"
            return 1
        return 0
    except Exception as error:
        report["status"] = "diagnostic_failed"
        report["error_type"] = type(error).__name__
        return 1
    finally:
        if process is not None and process.poll() is None:
            # Official native GDB attach uses DebugSetProcessKillOnExit(FALSE).
            # This is debugger cleanup only; never label target shutdown as pass.
            process.kill()
            process.wait(timeout=5)
            report["debugger_cleanup_required"] = True
        metadata_path.write_text(json.dumps(report, indent=2), encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
