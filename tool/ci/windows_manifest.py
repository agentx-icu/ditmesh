#!/usr/bin/env python3
"""Check the actual EXE RT_MANIFEST, without executing its code or dependencies."""
import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

ASM1 = 'urn:schemas-microsoft-com:asm.v1'
ASM3 = 'urn:schemas-microsoft-com:asm.v3'
WS2016 = 'http://schemas.microsoft.com/SMI/2016/WindowsSettings'
COMPAT = 'urn:schemas-microsoft-com:compatibility.v1'
WINDOWS10 = '{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}'


def check_xml(data):
    if not data or len(data) > 256 * 1024:
        raise ValueError('Manifest resource size is invalid')
    if data.startswith((b'\xff\xfe', b'\xfe\xff')):
        text = data.decode('utf-16')
    elif data.startswith(b'<\x00'):
        text = data.decode('utf-16-le')
    elif data.startswith(b'\x00<'):
        text = data.decode('utf-16-be')
    else:
        text = data.decode('utf-8-sig')
    if '<!DOCTYPE' in text.upper() or '<!ENTITY' in text.upper():
        raise ValueError('Manifest declarations must not contain a DTD or entity')
    root = ET.fromstring(text)
    if root.tag != f'{{{ASM1}}}assembly' or root.get('manifestVersion') != '1.0':
        raise ValueError('Expected an assembly manifest with the correct namespace')
    applications = root.findall(f'{{{ASM3}}}application')
    if len(applications) != 1:
        raise ValueError('Expected one Windows application declaration')
    settings = applications[0].findall(f'{{{ASM3}}}windowsSettings')
    if len(settings) != 1:
        raise ValueError('Expected one Windows settings declaration')
    for name, expected in (('longPathAware', 'true'), ('dpiAwareness', 'PerMonitorV2')):
        nodes = [node for node in root.iter() if node.tag.rsplit('}', 1)[-1] == name]
        exact = settings[0].findall(f'{{{WS2016}}}{name}')
        if len(nodes) != 1 or len(exact) != 1 or (exact[0].text or '').strip() != expected:
            raise ValueError(f'Manifest must declare exactly one namespace-correct {name}={expected}')
    supported = root.findall(f'{{{COMPAT}}}compatibility/{{{COMPAT}}}application/{{{COMPAT}}}supportedOS')
    if not any(node.get('Id', '').lower() == WINDOWS10 for node in supported):
        raise ValueError('Manifest lacks Windows 10/11 compatibility')
    return {'long_path_aware': True, 'dpi_awareness': 'PerMonitorV2',
            'windows_10_11_compatible': True}


def read_manifests(executable):
    if os.name != 'nt':
        raise ValueError('EXE resource extraction requires Windows')
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.LoadLibraryExW.argtypes = (wintypes.LPCWSTR, wintypes.HANDLE, wintypes.DWORD)
    kernel.LoadLibraryExW.restype = wintypes.HMODULE
    kernel.FreeLibrary.argtypes = (wintypes.HMODULE,)
    kernel.FreeLibrary.restype = wintypes.BOOL
    kernel.FindResourceExW.argtypes = (wintypes.HMODULE, wintypes.LPVOID, wintypes.LPVOID, wintypes.WORD)
    kernel.FindResourceExW.restype = wintypes.HANDLE
    kernel.SizeofResource.argtypes = (wintypes.HMODULE, wintypes.HANDLE)
    kernel.SizeofResource.restype = wintypes.DWORD
    kernel.LoadResource.argtypes = (wintypes.HMODULE, wintypes.HANDLE)
    kernel.LoadResource.restype = wintypes.HANDLE
    kernel.LockResource.argtypes = (wintypes.HANDLE,)
    kernel.LockResource.restype = wintypes.LPVOID
    # Integer resource identifiers are low-valued pointers, not C strings.
    callback_type = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HMODULE, wintypes.LPVOID,
                                      wintypes.LPVOID, wintypes.WORD, wintypes.LPARAM)
    kernel.EnumResourceLanguagesW.argtypes = (wintypes.HMODULE, wintypes.LPVOID, wintypes.LPVOID,
                                            callback_type, wintypes.LPARAM)
    kernel.EnumResourceLanguagesW.restype = wintypes.BOOL
    # Both flags load only resources/data, never DllMain, TLS or dependencies.
    module = kernel.LoadLibraryExW(str(Path(executable).resolve()), None, 0x02 | 0x20)
    if not module:
        raise ctypes.WinError(ctypes.get_last_error())
    resource_type = ctypes.c_void_p(24)  # RT_MANIFEST
    resource_id = ctypes.c_void_p(1)  # EXE process manifest
    try:
        languages = []
        @callback_type
        def collect(_module, _type, _name, language, _context):
            languages.append(language)
            return len(languages) <= 16
        if not kernel.EnumResourceLanguagesW(module, resource_type, resource_id, collect, 0):
            raise ValueError(f'EXE RT_MANIFEST #1 enumeration failed: {ctypes.get_last_error()}')
        if not languages or len(set(languages)) != len(languages):
            raise ValueError('EXE RT_MANIFEST languages are missing or duplicated')
        result = []
        for language in languages:
            resource = kernel.FindResourceExW(module, resource_type, resource_id, language)
            size = kernel.SizeofResource(module, resource) if resource else 0
            if not 0 < size <= 256 * 1024:
                raise ValueError('EXE RT_MANIFEST size is invalid')
            loaded = kernel.LoadResource(module, resource)
            address = kernel.LockResource(loaded) if loaded else None
            if not address:
                raise ValueError('EXE RT_MANIFEST could not be loaded')
            result.append((language, ctypes.string_at(address, size)))
        return result
    finally:
        kernel.FreeLibrary(module)


def check_executable(executable, manifest_output=None):
    path = Path(executable)
    resources = read_manifests(path)
    records = []
    for language, data in resources:
        records.append({'resource_id': 1, 'language': language,
                        'sha256': hashlib.sha256(data).hexdigest(), **check_xml(data)})
    if manifest_output:
        output = Path(manifest_output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(resources[0][1])
    return {'exe_sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'manifests': records}


def check_zip(archive):
    with zipfile.ZipFile(archive) as stream:
        entries = [item for item in stream.infolist() if item.filename.casefold() == 'ditmesh/ditmesh.exe']
        if len(entries) != 1 or entries[0].is_dir() or not 0 < entries[0].file_size <= 32 * 1024 * 1024:
            raise ValueError('ZIP must contain exactly one bounded DitMesh EXE')
        with tempfile.TemporaryDirectory(prefix='ditmesh manifest ZIP ') as directory:
            executable = Path(directory) / 'ditmesh.exe'
            executable.write_bytes(stream.read(entries[0]))
            result = check_executable(executable)
    result['zip_sha256'] = hashlib.sha256(Path(archive).read_bytes()).hexdigest()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--exe', type=Path)
    source.add_argument('--zip', type=Path)
    parser.add_argument('--manifest-output', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    if args.zip and args.manifest_output:
        parser.error('--manifest-output requires --exe')
    report = check_executable(args.exe, args.manifest_output) if args.exe else check_zip(args.zip)
    rendered = json.dumps(report, indent=2) + '\n'
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(rendered)
    print(rendered, end='')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, ET.ParseError, UnicodeError, zipfile.BadZipFile) as error:
        print(f'Windows manifest: {error}', file=sys.stderr)
        sys.exit(1)
