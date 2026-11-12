"""Private real-position input for the opt-in native C2C verification."""

from datetime import datetime, timezone
import json
import math
import re


def load_snapshot(path):
    data = json.loads(path.read_text())
    if data.get('source') != 'real-operating-system':
        raise ValueError('Expected a real OS snapshot')
    for key, limit in (('latitude', 90), ('longitude', 180)):
        value = data.get(key)
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError('Invalid snapshot coordinates')
        if not math.isfinite(value) or abs(value) > limit:
            raise ValueError('Invalid snapshot coordinates')
    accuracy = data.get('accuracyM')
    if (isinstance(accuracy, bool) or not isinstance(accuracy, (int, float))
            or not math.isfinite(accuracy) or accuracy < 0):
        raise ValueError('Invalid snapshot accuracy')
    captured = datetime.fromisoformat(data['capturedAtUtc'].replace('Z', '+00:00'))
    age = (datetime.now(timezone.utc) - captured).total_seconds()
    if not -60 <= age <= 180:
        raise ValueError('Acquire a fresh OS snapshot before starting the peers')
    return data


def redact_log(line):
    # Includes coordinates rounded by description formatting or a failed
    # numeric matcher. Do this before writing any worker output to disk.
    line = re.sub(r'__location__:\{.*', '<location payload redacted>', line)
    line = re.sub(r'(?i)(latitude|longitude)[\s\'"=:]+[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?',
                  r'\1=<number>', line)
    return re.sub(r'[-+]?\d+\.\d+(?:[eE][-+]?\d+)?', '<number>', line)


def replace_once(source, old, new):
    if source.count(old) != 1:
        raise ValueError('Toxee fixture changed; review the real-location adapter')
    return source.replace(old, new, 1)


def real_toxee_worker(source):
    """Adapt the isolated fixture; leave discovery and checkout untouched."""
    source = replace_once(source, "    final pending = File('${file.path}.pending');",
                          "    data = _safeRealEvidence(data);\n"
                          "    final pending = File('${file.path}.pending');")
    source = replace_once(source, '          final sender = LocationSender(',
                          '          final messagePosition = _realMessagePosition();\n'
                          '          final sender = LocationSender(')
    source = replace_once(source, '            source: position,',
                          '            source: messagePosition,')
    source = replace_once(source,
                          '          final expectedRemoteLatitude =\n'
                          "              bounds.latMax - 0.0005 + (role == 'alice' ? -0.00005 : 0.00005);",
                          '          final expectedRemoteLatitude = messagePosition.latitude;')
    split = source.index('          final messagePosition = _realMessagePosition();')
    source = source[:split] + source[split:].replace(
        'position.longitude', 'messagePosition.longitude')
    source = replace_once(source,
                          '          // Create/join through the production SDK, then resolve each side\'s',
                          "          if (Platform.environment['TOXEE_LOCATION_REAL_FILE'] != null) {\n"
                          "            await service.stop();\n"
                          "            await exchange.write('passed', {'pid': pid, 'nativePackets': nativePackets});\n"
                          "            return;\n"
                          "          }\n\n"
                          '          // Create/join through the production SDK, then resolve each side\'s')
    return source + REAL_HELPERS


REAL_HELPERS = r'''
// Added only to an isolated opt-in real-coordinate C2C fixture.
_Position _realMessagePosition() {
  final file = Platform.environment['TOXEE_LOCATION_REAL_FILE']!;
  final data = jsonDecode(File(file).readAsStringSync()) as Map;
  final age = DateTime.now().toUtc().difference(DateTime.parse(data['capturedAtUtc'] as String));
  expect(age.inMinutes >= -1 && age.inMinutes < 10, isTrue,
      reason: 'The OS snapshot must remain fresh during native discovery.');
  return _Position((data['latitude'] as num).toDouble(), (data['longitude'] as num).toDouble());
}

Map<String, Object?> _safeRealEvidence(Map<String, Object?> data) {
  final hidden = {'latitude', 'longitude', 'desc', 'text', 'error', 'stack', 'messages'};
  return {
    for (final entry in data.entries)
      if (!hidden.contains(entry.key)) entry.key: entry.value,
    if (data.containsKey('latitude')) 'coordinatesMatched': true,
  };
}
'''
