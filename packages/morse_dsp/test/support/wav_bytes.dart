import 'dart:typed_data';

/// Builds RIFF/WAVE bytes for tests, with optional extra chunks.
Uint8List wavBytes(
  Int16List samples, {
  int sampleRate = 48000,
  int channels = 1,
  int bits = 16,
  int format = 1,
  bool extensible = false,
  List<(String, List<int>)> before = const [],
  bool fmtAfterData = false,
  int? declaredDataSize,
}) {
  final BytesBuilder b = BytesBuilder();
  void tag(String s) => b.add(s.codeUnits);
  void u32(int v) =>
      b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  final BytesBuilder fmt = BytesBuilder();
  void fu16(int v) => fmt.add(
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List(),
  );
  void fu32(int v) => fmt.add(
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
  );
  fu16(extensible ? 0xFFFE : format);
  fu16(channels);
  fu32(sampleRate);
  fu32(sampleRate * channels * bits ~/ 8);
  fu16(channels * bits ~/ 8);
  fu16(bits);
  if (extensible) {
    fu16(22);
    fu16(bits);
    fu32(channels == 1 ? 4 : 3);
    fu16(format);
    fmt.add(List<int>.filled(14, 0));
  }
  final Uint8List fmtBody = fmt.toBytes();
  final Uint8List data = samples.buffer.asUint8List(
    samples.offsetInBytes,
    samples.lengthInBytes,
  );
  tag('RIFF');
  u32(0);
  tag('WAVE');
  void chunk(String id, List<int> body, {int? size}) {
    tag(id);
    u32(size ?? body.length);
    b.add(body);
    if (body.length.isOdd) b.addByte(0);
  }

  for (final (id, body) in before) {
    chunk(id, body);
  }
  if (!fmtAfterData) chunk('fmt ', fmtBody);
  if (fmtAfterData) {
    chunk('data', data);
    chunk('fmt ', fmtBody);
  } else {
    chunk('data', data, size: declaredDataSize);
  }
  final Uint8List bytes = b.toBytes();
  ByteData.sublistView(bytes).setUint32(4, bytes.length - 8, Endian.little);
  return bytes;
}
