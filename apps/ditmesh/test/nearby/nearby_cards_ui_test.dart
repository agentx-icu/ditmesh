import 'dart:async';

import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/nearby/geohash.dart';
import 'package:ditmesh/nearby/location_source.dart';
import 'package:ditmesh/nearby/nearby_crypto.dart';
import 'package:ditmesh/nearby/nearby_controller.dart';
import 'package:ditmesh/nearby/nearby_records.dart';
import 'package:ditmesh/nearby/nearby_service.dart';
import 'package:ditmesh/ui/nearby/nearby_cards.dart';
import 'package:ditmesh/ui/contacts/friend_request_inbox.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'nearby_service_test.dart' show FakeLocation, FakeTransport, settle;

class _ReplyController extends NearbyController {
  _ReplyController({
    required super.identity,
    required super.chat,
    required this.reply,
  }) : super(store: InMemoryKeyValueStore());

  final PendingIntent reply;

  @override
  PendingIntent? replyFor(String publicKey) => reply;
}

/// The SDK boundary records the exact friend-request wording and can hold a
/// send open, so double taps are tested while the first operation is pending.
class _RecordingChat implements ChatService {
  final requests = <({String address, String message})>[];
  Completer<void>? hold;

  @override
  Future<void> addFriend(String toxId, {String message = 'ditmesh CQ'}) async {
    requests.add((address: toxId, message: message));
    await hold?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Uses real signed presence and encrypted intents; only the OS and wire are
/// fakes. The peer card therefore sends through the actual privacy protocol.
class _NearbyFixture {
  _NearbyFixture(
    this.wire,
    this.nearby,
    this.peerKeys,
    this.cell,
    this.address,
  );
  final FakeTransport wire;
  final NearbyService nearby;
  final NearbySessionKeys peerKeys;
  final String cell;
  final String address;
  final chat = _RecordingChat();
  NearbyPeer get peer => nearby.peers.single;
  IncomingIntent get incoming => nearby.incomingIntents.single;
  int get privateSends => wire.sends.where((send) => send.peer != null).length;

  static Future<_NearbyFixture> create({
    String peerName = 'LONG CALLSIGN WITH MANY WORDS',
    String message = 'CQ from nearby',
  }) async {
    final now = DateTime.utc(2026, 11, 12, 12);
    final (latitude: lat, longitude: lon) = Geohash.decode('wx4g0');
    final wire = FakeTransport();
    final address = FakeIdentityService.toxIdForSeed(1);
    final nearby = NearbyService(
      transport: wire,
      location: FakeLocation(
        LocationFix(latitude: lat, longitude: lon, accuracyM: 20, at: now),
        now: () => now,
      ),
      selfAddress: () async => address,
      displayName: () => 'My callsign',
      clock: () => now,
    );
    await nearby.start();
    final cell = await NearbyService.chatIdForSeed(
      NearbyCrypto.seedForCell('wx4g0'),
    );
    wire.emit(RendezvousJoined(cell, founded: true));
    await settle();
    final peerKeys = await NearbyCrypto.newSessionKeys();
    final presence = (await PresenceRecord.encode(
      PresenceRecord(
        skHex: peerKeys.skHex,
        ekHex: peerKeys.ekHex,
        seq: 1,
        exp: now.millisecondsSinceEpoch ~/ 1000 + 180,
        name: peerName,
        avatarHex: '',
        latE3: (lat * 1000).round() + 2,
        lonE3: (lon * 1000).round(),
        cells: const ['wx4g0'],
      ),
      peerKeys,
    ))!;
    wire.emit(
      RendezvousPacket(
        cell,
        peerPkHex: 'b' * 64,
        isPrivate: false,
        payload: presence,
      ),
    );
    await settle();
    final intent = (await IntentRecord.encode(
      keys: peerKeys,
      recipientEkHex: nearby.sessionKeys!.ekHex,
      body: IntentBody(
        address: FakeIdentityService.toxIdForSeed(2).toLowerCase(),
        nonceHex: 'ab' * NearbyLimits.nonceBytes,
        message: message,
        exp: now.millisecondsSinceEpoch ~/ 1000 + 600,
      ),
    ))!;
    wire.emit(
      RendezvousPacket(
        cell,
        peerPkHex: 'b' * 64,
        isPrivate: true,
        payload: intent,
      ),
    );
    await settle();
    return _NearbyFixture(wire, nearby, peerKeys, cell, address);
  }

  Future<void> dispose() async {
    if (chat.hold case final hold? when !hold.isCompleted) hold.complete();
    await nearby.stop();
    nearby.dispose();
  }
}

Future<_NearbyFixture> _fixture(
  WidgetTester tester, {
  String peerName = 'LONG CALLSIGN WITH MANY WORDS',
  String message = 'CQ from nearby',
}) async {
  final fixture = (await tester.runAsync(
    () => _NearbyFixture.create(peerName: peerName, message: message),
  ))!;
  addTearDown(fixture.dispose);
  expect(fixture.nearby.peers, hasLength(1));
  expect(fixture.nearby.incomingIntents, hasLength(1));
  return fixture;
}

Future<void> _pump(
  WidgetTester tester,
  _NearbyFixture fixture, {
  bool peer = true,
  bool incoming = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (peer)
              NearbyPeerCard(peer: fixture.peer, nearby: fixture.nearby),
            if (incoming)
              NearbyIncomingCard(
                intent: fixture.incoming,
                nearby: fixture.nearby,
                service: fixture.chat,
              ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _compose(WidgetTester tester, {String text = 'CQ test'}) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Say hi'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
  await tester.pumpAndSettle();
  expect(find.text('Share your Tox ID?'), findsOneWidget);
}

void main() {
  for (final testCase in [
    (
      label: 'Unicode name',
      raw: '\u202EBOB\u2069\u0085\u2028NORTH',
      shown: 'BOB NORTH',
    ),
    (label: 'control-only name', raw: '\u202E\u2069\u0085', shown: null),
  ]) {
    testWidgets(
      'nearby friend replies clean ${testCase.label} without changing nonce wording',
      (tester) async {
        final identity = FakeIdentityService();
        final chat = FakeChatService();
        final reply = PendingIntent(
          nonceHex: 'ab' * NearbyLimits.nonceBytes,
          expiresAt: DateTime.utc(2026, 11, 12, 12, 10),
          targetSkHex: 'a' * 64,
          targetEkHex: 'b' * 64,
          targetName: testCase.raw,
        );
        final controller = _ReplyController(
          identity: identity,
          chat: chat,
          reply: reply,
        );
        addTearDown(() async {
          controller.dispose();
          await chat.dispose();
          await identity.dispose();
        });
        final key = 'D' * 64;
        final wording = '${NearbyLimits.requestTag}${reply.nonceHex} \u202ECQ';
        chat.receiveFriendRequest(key, message: wording);
        final strings = lookupS(const Locale('en'));
        final name = testCase.shown ?? strings.nearbyUnnamed;
        await tester.pumpWidget(
          ChangeNotifierProvider<NearbyController>.value(
            value: controller,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              home: Scaffold(body: FriendRequestInbox(service: chat)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final tile = tester.widget<ListTile>(find.byKey(ValueKey('req_$key')));
        expect((tile.title! as Text).data, name);
        expect(
          (tile.subtitle! as Text).data,
          contains(strings.nearbyReplyBody(name)),
        );
        expect(find.textContaining(testCase.raw), findsNothing);
        expect(reply.targetName, testCase.raw);
        expect(chat.friendRequests.single.message, wording);
        await tester.tap(find.byTooltip(strings.chatAccept));
        await tester.pumpAndSettle();
        expect(chat.friendRequests, isEmpty);
        expect(chat.friends.map((friend) => friend.publicKey), contains(key));
      },
    );
  }

  testWidgets('peer names are safe in cards, compose titles and consent', (
    tester,
  ) async {
    const rawName = '\u202EBOB\u2069\u0085\u2028NORTH';
    final fixture = await _fixture(tester, peerName: rawName);
    final strings = lookupS(const Locale('en'));
    await _pump(tester, fixture);
    expect(find.text('BOB NORTH'), findsOneWidget);
    expect(fixture.peer.name, rawName, reason: 'signed records remain intact');

    await tester.tap(find.widgetWithText(FilledButton, 'Say hi'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('BOB NORTH'),
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'CQ');
    await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
    await tester.pumpAndSettle();
    expect(find.text(strings.nearbyConsentBody('BOB NORTH')), findsOneWidget);
    expect(find.textContaining(rawName), findsNothing);
    expect(fixture.privateSends, 0);
  });

  testWidgets('incoming wording is cleaned only for display and consent', (
    tester,
  ) async {
    const rawName = '\u202EBOB\u2069\u0085\u2028NORTH';
    const rawMessage = '\u202Emeet\u2069\u0085\nby the gate';
    final fixture = await _fixture(
      tester,
      peerName: rawName,
      message: rawMessage,
    );
    final strings = lookupS(const Locale('en'));
    await _pump(tester, fixture, peer: false, incoming: true);
    expect(find.text(strings.nearbyIncomingBody('BOB NORTH')), findsOneWidget);
    expect(find.text('“meet\nby the gate”'), findsOneWidget);
    expect(find.textContaining(rawName), findsNothing);
    expect(find.textContaining(rawMessage), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();
    expect(find.text(strings.nearbyConsentBody('BOB NORTH')), findsOneWidget);
    final intent = fixture.incoming;
    expect(intent.message, rawMessage);
    await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
    await tester.pumpAndSettle();
    expect(fixture.chat.requests.single.message, intent.requestWording);
  });

  testWidgets('control-only names use the unnamed fallback before initials', (
    tester,
  ) async {
    final fixture = await _fixture(tester, peerName: '\u202E\u2069\u0085');
    final strings = lookupS(const Locale('en'));
    await _pump(tester, fixture, incoming: true);
    expect(tester.takeException(), isNull);
    expect(find.text(strings.nearbyUnnamed), findsOneWidget);
    expect(
      find.text(strings.nearbyIncomingBody(strings.nearbyUnnamed)),
      findsOneWidget,
    );
    await _compose(tester);
    expect(
      find.text(strings.nearbyConsentBody(strings.nearbyUnnamed)),
      findsOneWidget,
    );
  });

  testWidgets(
    'say hi does not send before sharing consent or after cancellation',
    (tester) async {
      final fixture = await _fixture(tester);
      await _pump(tester, fixture);
      await tester.tap(find.widgetWithText(FilledButton, 'Say hi'));
      await tester.pumpAndSettle();
      expect(fixture.privateSends, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fixture.privateSends, 0);

      await _compose(tester);
      expect(fixture.privateSends, 0);
      expect(fixture.nearby.pendingIntents, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fixture.privateSends, 0);
      expect(fixture.nearby.pendingIntents, isEmpty);
    },
  );

  testWidgets('say hi shares one encrypted intent only after confirmation', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _pump(tester, fixture);
    await _compose(tester, text: 'CQ confirmed');
    expect(fixture.privateSends, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
    await tester.pumpAndSettle();
    // Crypto completes in the real event loop, independently of animations.
    await tester.runAsync(settle);
    await tester.pumpAndSettle();
    expect(fixture.privateSends, 1);
    expect(fixture.nearby.pendingIntents, hasLength(1));
    final send = fixture.wire.sends.singleWhere((send) => send.peer != null);
    final body = await tester.runAsync(() async {
      final record = await IntentRecord.decode(send.payload);
      return record!.open(
        fixture.peerKeys,
        DateTime.utc(2026, 11, 12, 12).millisecondsSinceEpoch ~/ 1000,
      );
    });
    expect(body!.address, fixture.address.toLowerCase());
    expect(body.message, 'CQ confirmed');
  });

  testWidgets(
    'incoming accept asks consent and cancellation sends no request',
    (tester) async {
      final fixture = await _fixture(tester);
      await _pump(tester, fixture, peer: false, incoming: true);
      await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
      await tester.pumpAndSettle();
      expect(find.text('Share your Tox ID?'), findsOneWidget);
      expect(fixture.chat.requests, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fixture.chat.requests, isEmpty);
      expect(fixture.nearby.incomingIntents, hasLength(1));
    },
  );

  testWidgets(
    'incoming confirmation sends exact nonce wording once despite repeated taps',
    (tester) async {
      final fixture = await _fixture(tester);
      final intent = fixture.incoming;
      fixture.chat.hold = Completer<void>();
      await _pump(tester, fixture, peer: false, incoming: true);
      final accept = find.widgetWithText(FilledButton, 'Accept');
      // Invoke the still-rendered handler twice before a frame can disable
      // it; normal taps after this frame hit the confirmation modal barrier.
      final acceptCallback = tester.widget<FilledButton>(accept).onPressed!;
      acceptCallback();
      acceptCallback();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(fixture.chat.requests, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
      await tester.pumpAndSettle();
      expect(fixture.chat.requests, [
        (address: intent.address.toUpperCase(), message: intent.requestWording),
      ]);
      expect(tester.widget<FilledButton>(accept).onPressed, isNull);
      expect(fixture.nearby.incomingIntents, hasLength(1));
      fixture.chat.hold!.complete();
      await tester.pumpAndSettle();
      expect(fixture.chat.requests, hasLength(1));
      expect(fixture.nearby.incomingIntents, isEmpty);
    },
  );

  testWidgets('cards fit 360 pixels with German labels and double-size text', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    await _pump(
      tester,
      fixture,
      incoming: true,
      locale: const Locale('de'),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byType(NearbyIncomingCard), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
