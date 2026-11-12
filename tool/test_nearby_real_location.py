import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
import tempfile
import unittest

from nearby_real_location import load_snapshot, real_toxee_worker, redact_log


class RealLocationInputTest(unittest.TestCase):
    def snapshot(self, **changes):
        data = dict(latitude=0.012345, longitude=-140.012345, accuracyM=20,
                    capturedAtUtc=datetime.now(timezone.utc).isoformat(),
                    source='real-operating-system')
        data.update(changes)
        return data

    def read(self, data):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'snapshot.json'
            path.write_text(json.dumps(data))
            return load_snapshot(path)

    def test_accepts_valid_fresh_input(self):
        data = self.snapshot()
        self.assertEqual(self.read(data), data)

    def test_rejects_stale_synthetic_and_invalid_input(self):
        stale = (datetime.now(timezone.utc) - timedelta(minutes=4)).isoformat()
        for changes in [dict(capturedAtUtc=stale), dict(source='synthetic'),
                        dict(latitude=91), dict(longitude=float('nan')),
                        dict(latitude=True), dict(accuracyM=-1)]:
            with self.subTest(changes=list(changes)):
                with self.assertRaises(ValueError):
                    self.read(self.snapshot(**changes))

    def test_stdout_redaction_covers_payloads_and_numeric_failure_messages(self):
        raw = 'Actual: 0.012345 Expected: -140.012345 desc 0.0123, -140.0123'
        redacted = redact_log(raw)
        for value in ['0.012345', '-140.012345', '0.0123', '-140.0123']:
            self.assertNotIn(value, redacted)
        self.assertNotIn('latitude', redact_log('__location__:{"latitude":1}'))
        self.assertEqual(redact_log('latitude=40 longitude=-140'),
                         'latitude=<number> longitude=<number>')

    def test_adapter_keeps_real_coordinates_out_of_discovery(self):
        fixture = (Path(__file__).resolve().parents[2] /
                   'toxee/test/native/location_network_peer_test.dart')
        if not fixture.is_file():
            self.skipTest('The optional local Toxee checkout is not present')
        source = fixture.read_text()
        adapted = real_toxee_worker(source)
        self.assertIn('location: position,', adapted)
        self.assertIn('source: messagePosition,', adapted)
        self.assertIn('data = _safeRealEvidence(data);', adapted)
        with self.assertRaises(ValueError):
            real_toxee_worker(source.replace('final sender = LocationSender(',
                                              'final renamed = LocationSender('))


if __name__ == '__main__':
    unittest.main()
