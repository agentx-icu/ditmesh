import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

// Complete nonstandard timing fixtures for the real native workers. This
// test-only alphabet keeps the backend independent of Morse presentation code.
KeyedRecording realPeerRhythm(
  String sender,
  String text, {
  bool second = false,
}) {
  const alphabet = [
    '.-',
    '-...',
    '-.-.',
    '-..',
    '.',
    '..-.',
    '--.',
    '....',
    '..',
    '.---',
    '-.-',
    '.-..',
    '--',
    '-.',
    '---',
    '.--.',
    '--.-',
    '.-.',
    '...',
    '-',
    '..-',
    '...-',
    '.--',
    '-..-',
    '-.--',
    '--..',
  ];
  final dit = second
      ? 111
      : sender == 'alice'
      ? 83
      : 110;
  final dah = second
      ? 299
      : sender == 'alice'
      ? 256
      : 301;
  final gap = second
      ? 67
      : sender == 'alice'
      ? 117
      : 71;
  final spans = <int>[];
  var mark = 0;
  final words = text.split(' ');
  for (var w = 0; w < words.length; w++) {
    if (w > 0) spans.add(787 + w * 11);
    final codes = words[w].codeUnits;
    for (var c = 0; c < codes.length; c++) {
      if (c > 0) spans.add(353 + c * 7);
      final pattern = alphabet[codes[c] - 65];
      for (var i = 0; i < pattern.length; i++) {
        if (i > 0) spans.add(gap + i);
        spans.add((pattern[i] == '.' ? dit : dah) + mark++ % 5);
      }
    }
  }
  return KeyedRecording(durationsMs: spans);
}
