import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:test/test.dart';

void main() {
  test('clean removes bidi controls and C0/C1 controls, keeps text', () {
    // "Alice" spoofed with a right-to-left override and an isolate.
    expect(PeerText.clean('\u202Eecila\u202C'), 'ecila');
    expect(PeerText.clean('A\u2066B\u2069C\u200E\u200F\u061C'), 'ABC');
    expect(PeerText.clean('bell\u0007 del\u007F c1\u0085'), 'bell del c1');
    expect(PeerText.clean('CQ CQ\nDE W1AW\tK'), 'CQ CQ\nDE W1AW\tK');
    expect(PeerText.clean('日本語 ünïcödé 🙂'), '日本語 ünïcödé 🙂');
  });

  test('singleLine folds line breaks for labels', () {
    expect(PeerText.singleLine('  Bob\n\nthe\tbuilder \u202E '), 'Bob the builder');
  });

  test('Unicode line and paragraph separators fold in labels', () {
    expect(PeerText.singleLine('Ann\u2028Fake line\u2029x'), 'Ann Fake line x');
  });
}
