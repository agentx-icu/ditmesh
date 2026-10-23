from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET
import zipfile

import windows_manifest as manifest

SOURCE = Path(__file__).resolve().parents[2] / 'apps/ditmesh/windows/runner/runner.exe.manifest'


class WindowsManifestTests(unittest.TestCase):
    def setUp(self):
        self.data = SOURCE.read_bytes()

    def test_actual_source_declares_all_three_windows_contracts(self):
        self.assertTrue(manifest.check_xml(self.data)['long_path_aware'])

    def test_utf8_bom_and_utf16_resource_encodings_are_supported(self):
        text = self.data.decode('utf-8').replace('encoding="UTF-8"', 'encoding="UTF-16"')
        for data in (b'\xef\xbb\xbf' + self.data, text.encode('utf-16'),
                     text.encode('utf-16-le'), text.encode('utf-16-be')):
            with self.subTest(prefix=data[:8]):
                self.assertTrue(manifest.check_xml(data)['long_path_aware'])

    def test_missing_false_or_namespace_decoy_does_not_enable_long_paths(self):
        for previous, changed in ((b'>true</longPathAware>', b'>false</longPathAware>'),
                                  (b'longPathAware', b'otherSetting'),
                                  (b'/SMI/2016/WindowsSettings">true', b'/SMI/2005/WindowsSettings">true')):
            with self.subTest(changed=changed), self.assertRaisesRegex(ValueError, 'longPathAware'):
                manifest.check_xml(self.data.replace(previous, changed))

    def test_duplicate_or_wrong_parent_settings_are_rejected(self):
        root = ET.fromstring(self.data)
        node = root.find(f'{{{manifest.ASM3}}}application/{{{manifest.ASM3}}}windowsSettings')
        ET.SubElement(node, f'{{{manifest.WS2016}}}longPathAware').text = 'true'
        with self.assertRaisesRegex(ValueError, 'longPathAware'):
            manifest.check_xml(ET.tostring(root))
        with self.assertRaisesRegex(ValueError, 'Windows application'):
            manifest.check_xml(self.data.replace(manifest.ASM3.encode(), b'urn:wrong-namespace'))

    def test_dpi_compatibility_and_root_namespaces_remain_required(self):
        for previous, changed in ((b'PerMonitorV2', b'System'),
                                  (manifest.WINDOWS10.encode(), b'{invalid}'),
                                  (manifest.ASM1.encode(), b'urn:wrong-assembly')):
            with self.subTest(changed=changed), self.assertRaises(ValueError):
                manifest.check_xml(self.data.replace(previous, changed))

    def test_malformed_oversize_and_entity_xml_fail_closed(self):
        for data in (b'', b'broken XML', b'x' * (256 * 1024 + 1),
                     b'<!DOCTYPE assembly [<!ENTITY secret "private">]>' + self.data,
                     ('<!DOCTYPE assembly>' + self.data.decode()).encode('utf-16')):
            with self.subTest(prefix=data[:20]), self.assertRaises((ValueError, ET.ParseError)):
                manifest.check_xml(data)

    def test_every_embedded_language_must_pass_before_manifest_is_written(self):
        with tempfile.TemporaryDirectory() as directory:
            exe = Path(directory) / 'ditmesh.exe'
            exe.write_bytes(b'fixture, resource API mocked only')
            output = Path(directory) / 'exported.manifest'
            bad = self.data.replace(b'>true</longPathAware>', b'>false</longPathAware>')
            with patch.object(manifest, 'read_manifests', return_value=[(0, self.data), (1033, bad)]):
                with self.assertRaisesRegex(ValueError, 'longPathAware'):
                    manifest.check_executable(exe, output)
            self.assertFalse(output.exists())
            with patch.object(manifest, 'read_manifests', return_value=[(0, self.data)]):
                report = manifest.check_executable(exe, output)
            self.assertEqual(output.read_bytes(), self.data)
            self.assertEqual(report['manifests'][0]['resource_id'], 1)

    def test_zip_reads_only_the_final_executable_into_a_fixed_temporary_path(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / 'release.zip'
            with zipfile.ZipFile(archive, 'w') as stream:
                stream.writestr('ditmesh/ditmesh.exe', b'exact final PE bytes')
                stream.writestr('../unrelated', b'never extracted')
            def check(path):
                self.assertEqual(path.name, 'ditmesh.exe')
                self.assertEqual(path.read_bytes(), b'exact final PE bytes')
                self.assertFalse((path.parent / 'unrelated').exists())
                return {'exe_sha256': 'fixture'}
            with patch.object(manifest, 'check_executable', side_effect=check) as invoked:
                result = manifest.check_zip(archive)
            self.assertEqual(invoked.call_count, 1)
            self.assertEqual(len(result['zip_sha256']), 64)

    def test_zip_missing_empty_and_case_colliding_executables_are_rejected(self):
        for entries in ([], [('ditmesh/ditmesh.exe', b'')],
                        [('ditmesh/ditmesh.exe', b'one'), ('DitMesh/DITMESH.exe', b'two')]):
            with self.subTest(entries=entries), tempfile.TemporaryDirectory() as directory:
                archive = Path(directory) / 'release.zip'
                with zipfile.ZipFile(archive, 'w') as stream:
                    for path, data in entries:
                        stream.writestr(path, data)
                with patch.object(manifest, 'check_executable') as invoked:
                    with self.assertRaisesRegex(ValueError, 'exactly one'):
                        manifest.check_zip(archive)
                    invoked.assert_not_called()


if __name__ == '__main__':
    unittest.main()
