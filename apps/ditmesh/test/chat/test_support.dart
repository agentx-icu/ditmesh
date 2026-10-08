import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh/ui/chat/morse_playback_settings.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

// The fake's test hooks are an extension; re-export so every chat test that
// imports this file can call `service.receiveMessage(...)` etc.
export 'package:ditmesh/l10n/generated/s.dart' show S;
export 'package:ditmesh_chat_api/testing.dart';

/// The English strings the harness renders with (`MaterialApp.locale` is
/// pinned to `en`), so finders can say `find.text(s.chatSend)`.
final S s = lookupS(const Locale('en'));

/// 64-hex public keys / 76-hex Tox IDs used across the chat tests.
final String kPeerKey = 'A' * 64;
final String kPeerToxId = '${'B' * 64}${'0' * 12}';
final String kSelfKey = 'F' * 64;
// Nospam 11111111 and FF..FF cancel out in both checksum lanes: checksum 0000.
final String kSelfToxId = '$kSelfKey${'1' * 8}0000';

const Size kPhone = Size(390, 844);
const Size kDesktop = Size(1280, 800);

/// Minimal [IdentityService] for the chat UI: only [current] is meaningful.
/// Everything else is unreachable from the chat/contacts/groups screens.
final class StubIdentityService implements IdentityService {
  StubIdentityService({Identity? identity})
    : current = identity ?? Identity(toxId: kSelfToxId, displayName: 'Me');

  @override
  final Identity? current;

  @override
  ConnectionStatus get connectionStatus => ConnectionStatus.online;

  @override
  Stream<ConnectionStatus> get connectionChanges => const Stream.empty();

  @override
  Stream<Identity?> get identityChanges => const Stream.empty();

  @override
  Future<IdentityState> inspect() async => IdentityState.ready;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<String> dataDirectory() async => '/tmp/ditmesh-test';

  @override
  Future<Identity> open() async => current!;

  // The following exist only to satisfy the interface; unreachable in tests.
  @override
  Future<Identity> create({required String displayName, String? password}) =>
      throw UnimplementedError();

  @override
  Future<Identity> unlock(String password) => throw UnimplementedError();

  @override
  Future<void> changePassword({String? oldPassword, String? newPassword}) =>
      throw UnimplementedError();

  @override
  Future<Identity> updateProfile({
    String? displayName,
    String? statusMessage,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> exportBackup({bool includeMedia = false}) =>
      throw UnimplementedError();

  @override
  Future<Identity> importBackup(Uint8List bytes, {String? password}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteIdentity() => throw UnimplementedError();
}

/// Everything a chat widget test needs, wired the way `main.dart` will.
final class ChatHarness {
  factory ChatHarness({FakeChatService? service, DateTime? now}) {
    final FakeClock clock = FakeClock();
    return ChatHarness._(
      service ??
          FakeChatService(
            selfPublicKey: kSelfKey,
            clock: () => now ?? DateTime(2026, 9, 30, 12),
          ),
      clock,
      MorsePlaybackController(sink: const NullSink(), clock: clock),
    );
  }

  ChatHarness._(this.service, this.clock, this.playback)
    : identity = StubIdentityService(),
      settings = MorsePlaybackSettings();

  final FakeChatService service;
  final StubIdentityService identity;
  final MorsePlaybackSettings settings;
  final FakeClock clock;
  final MorsePlaybackController playback;

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      Provider<ChatService>.value(value: service),
      Provider<IdentityService>.value(value: identity),
      ChangeNotifierProvider<MorsePlaybackSettings>.value(value: settings),
      ChangeNotifierProvider<MorsePlaybackController>.value(value: playback),
    ],
    child: MaterialApp(
      theme: DitmeshTheme.light(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );

  Future<void> dispose() async {
    playback.dispose();
    settings.dispose();
    await service.dispose();
  }

  /// A friend named Ann plus (optionally) a conversation seeded with one
  /// inbound message so it shows in the list.
  Friend addAnn({bool online = false, bool withMessage = true}) {
    final Friend ann = Friend(
      publicKey: kPeerKey,
      displayName: 'Ann',
      online: online,
    );
    service.addFakeFriend(ann);
    if (withMessage) {
      service.receiveMessage('c2c_$kPeerKey', 'CQ CQ DE ANN');
    }
    return ann;
  }
}

/// Pumps [child] inside a [ChatHarness] at [size]; registers tear-downs.
Future<ChatHarness> pumpChat(
  WidgetTester tester,
  Widget Function(ChatHarness h) build, {
  Size size = kPhone,
  ChatHarness? harness,
}) async {
  final ChatHarness h = harness ?? ChatHarness();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(h.dispose);
  await tester.pumpWidget(h.wrap(build(h)));
  await tester.pumpAndSettle();
  return h;
}

/// Puts [text] in the composer's draft. The field is read-only (chat is
/// keyed, not typed), so tests fill it the way decoded keying does.
Future<void> keyIn(WidgetTester tester, String text) async {
  tester
      .widget<TextField>(find.byType(TextField))
      .controller!
      .value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  await tester.pump();
}
