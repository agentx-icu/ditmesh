import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/notifications/notification_prefs.dart';

void main() {
  test('defaults: everything on, nothing muted', () {
    final NotificationPrefs p = NotificationPrefs();
    addTearDown(p.dispose);
    expect(p.enabled, isTrue);
    expect(p.showText, isTrue);
    expect(p.showPattern, isTrue);
    expect(p.sound, isTrue);
    expect(p.mutedConversations, isEmpty);
    expect(p.isMuted('c2c_X'), isFalse);
  });

  test('JSON round-trip preserves every field', () {
    final NotificationPrefs p = NotificationPrefs(
      enabled: false,
      showText: false,
      showPattern: true,
      sound: false,
      muted: const <String>['group_2', 'c2c_A'],
    );
    addTearDown(p.dispose);
    final NotificationPrefs back = NotificationPrefs.fromJson(p.toJson());
    addTearDown(back.dispose);
    expect(back.enabled, isFalse);
    expect(back.showText, isFalse);
    expect(back.showPattern, isTrue);
    expect(back.sound, isFalse);
    expect(back.mutedConversations, <String>{'c2c_A', 'group_2'});
    expect(p.toJson()['muted'], <String>['c2c_A', 'group_2']); // sorted
  });

  test('fromJson tolerates missing and malformed fields', () {
    final NotificationPrefs p = NotificationPrefs.fromJson(<String, Object?>{
      'sound': false,
      'muted': <Object?>['ok', 3, null],
    });
    addTearDown(p.dispose);
    expect(p.enabled, isTrue);
    expect(p.sound, isFalse);
    expect(p.mutedConversations, <String>{'ok'});
  });

  test('notifies only on actual changes', () {
    final NotificationPrefs p = NotificationPrefs();
    addTearDown(p.dispose);
    var notified = 0;
    p.addListener(() => notified++);

    p.sound = true; // unchanged
    p.setMuted('c2c_A', false); // unchanged
    expect(notified, 0);

    p.sound = false;
    p.setMuted('c2c_A', true);
    p.setMuted('c2c_A', true); // unchanged
    p.showPattern = false;
    expect(notified, 3);
    expect(p.isMuted('c2c_A'), isTrue);

    p.setMuted('c2c_A', false);
    expect(notified, 4);
    expect(p.isMuted('c2c_A'), isFalse);
  });
}
