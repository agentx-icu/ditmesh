import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/contacts/add_friend_sheet.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/contacts/tox_id.dart';

import 'test_support.dart';

void main() {
  group('validateToxId', () {
    test('accepts 76 hex chars, tolerates whitespace and tox: prefix', () {
      expect(validateToxId(kPeerToxId), isNull);
      expect(validateToxId(' tox:${kPeerToxId.toLowerCase()} '), isNull);
      expect(validateToxIdInput(s, kPeerToxId), isNull);
    });

    test('rejects wrong length, non-hex and own id', () {
      expect(validateToxId(''), ToxIdError.invalid);
      expect(validateToxId('${'A' * 75}G'), ToxIdError.invalid);
      expect(validateToxId('A' * 75), ToxIdError.invalid);
      expect(validateToxId('A' * 77), ToxIdError.invalid);
      expect(validateToxId(kSelfToxId, ownToxId: kSelfToxId), ToxIdError.own);
    });

    test('rejects a typo through the Tox address checksum', () {
      // A real address: key 0x01..0x20, nospam DEADBEEF, checksum over all.
      final String key = [
        for (var i = 1; i <= 32; i++) i.toRadixString(16).padLeft(2, '0'),
      ].join().toUpperCase();
      const String nospam = 'DEADBEEF';
      var even = 0;
      var odd = 0;
      final String body = '$key$nospam';
      for (var i = 0; i < body.length; i += 2) {
        final int b = int.parse(body.substring(i, i + 2), radix: 16);
        if ((i ~/ 2).isEven) {
          even ^= b;
        } else {
          odd ^= b;
        }
      }
      final String checksum =
          '${even.toRadixString(16).padLeft(2, '0')}'
                  '${odd.toRadixString(16).padLeft(2, '0')}'
              .toUpperCase();
      final String valid = '$body$checksum';
      expect(validateToxId(valid), isNull);
      // One flipped character anywhere breaks the checksum.
      final String typo = '${valid.substring(0, 10)}'
          '${valid[10] == '0' ? '1' : '0'}${valid.substring(11)}';
      expect(validateToxId(typo), ToxIdError.invalid);
      expect(validateToxId('${body}0000'), ToxIdError.invalid);
    });

    test('the form validator renders the codes in the given locale', () {
      expect(validateToxIdInput(s, 'A' * 75), s.chatToxIdInvalid);
      expect(
        validateToxIdInput(s, kSelfToxId, ownToxId: kSelfToxId),
        s.chatToxIdOwn,
      );
    });
  });

  testWidgets('invalid id shows the error and does not call the service', (
    tester,
  ) async {
    final ChatHarness h = await pumpChat(
      tester,
      (h) => Scaffold(body: AddFriendForm(service: h.service)),
    );
    await tester.enterText(find.byType(TextFormField).first, 'not-a-tox-id');
    await tester.pump();
    expect(find.text(s.chatToxIdInvalid), findsOneWidget);
    await tester.tap(find.text(s.chatSendRequest));
    await tester.pumpAndSettle();
    expect(h.service.outgoingFriendRequests, isEmpty);
  });

  testWidgets('valid id sends the request through the service', (tester) async {
    final ChatHarness h = await pumpChat(
      tester,
      (h) => Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showAddFriendSheet(
                context,
                service: h.service,
                canScan: false,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Desktop: no scan action, the hint explains why. (Mobile gets a
    // labelled button below the field instead of a suffix icon: see the
    // `canScan: true` test.)
    expect(find.text(s.chatScanQrDesktopHint), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    // The greeting defaults to the localized "DitMesh CQ".
    expect(find.text(s.chatDefaultRequestMessage), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      kPeerToxId.toLowerCase(),
    );
    await tester.pump();
    expect(find.text(s.chatToxIdInvalid), findsNothing);
    await tester.tap(find.text(s.chatSendRequest));
    await tester.pumpAndSettle();
    expect(h.service.outgoingFriendRequests, [kPeerToxId]);
    expect(h.service.friends.single.publicKey, kPeerToxId.substring(0, 64));
    expect(find.byType(AddFriendForm), findsNothing); // sheet closed
  });

  testWidgets('adding yourself is refused by the backend and surfaced', (
    tester,
  ) async {
    final ChatHarness h = await pumpChat(
      tester,
      (h) => Scaffold(body: AddFriendForm(service: h.service)),
    );
    await tester.enterText(find.byType(TextFormField).first, kSelfToxId);
    await tester.tap(find.text(s.chatSendRequest));
    await tester.pumpAndSettle();
    expect(find.text(s.chatToxIdOwn), findsOneWidget);
    expect(h.service.friends, isEmpty);
  });

  testWidgets('contacts page lists friends with requests and accepts one', (
    tester,
  ) async {
    final ChatHarness h = await pumpChat(tester, (h) {
      h.addAnn(online: true, withMessage: false);
      h.service.receiveFriendRequest('D' * 64, message: 'CQ DE DAN');
      return ContactsPage(
        service: h.service,
        identity: h.identity,
        onOpenConversation: (_) {},
        canScan: false,
      );
    });
    expect(find.text('Ann'), findsOneWidget);
    expect(find.text(s.connectionOnline), findsOneWidget);
    expect(find.text(s.chatFriendsCount(1)), findsOneWidget);
    expect(find.text('CQ DE DAN'), findsOneWidget);
    await tester.tap(find.byTooltip(s.chatAccept));
    await tester.pumpAndSettle();
    expect(h.service.friendRequests, isEmpty);
    expect(h.service.friends, hasLength(2));
    expect(find.text('CQ DE DAN'), findsNothing);

    // My Tox ID sheet renders the identity's id.
    await tester.tap(find.byTooltip(s.chatMyToxId));
    await tester.pumpAndSettle();
    expect(find.text(kSelfToxId), findsOneWidget);
  });

  testWidgets('phone: the scan action is a labelled button below the field', (
    tester,
  ) async {
    final h = ChatHarness();
    addTearDown(h.dispose);
    await tester.pumpWidget(
      h.wrap(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAddFriendSheet(
                  context,
                  service: h.service,
                  canScan: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Not inside the text field's suffix slot: a Tooltip there raised a
    // semantics assertion on every platform while the sheet dismissed.
    expect(find.byType(Tooltip), findsNothing);
    final scan = find.widgetWithText(TextButton, s.chatScanQr);
    expect(scan, findsOneWidget);
    expect(tester.widget<TextButton>(scan).onPressed, isNotNull);
    expect(find.text(s.chatScanQrDesktopHint), findsNothing);
  });

  testWidgets('phone: sending dismisses the sheet with semantics enabled', (
    tester,
  ) async {
    // Regression for the "Invisible SemanticsNodes" assertion raised while
    // the sheet slid away after a send (Tooltip in the field's suffix slot).
    // Disposed at the end of the body: the end-of-test check runs before
    // addTearDown callbacks.
    final handle = tester.ensureSemantics();
    final h = ChatHarness();
    addTearDown(h.dispose);
    await tester.pumpWidget(
      h.wrap(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAddFriendSheet(
                  context,
                  service: h.service,
                  canScan: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, kPeerToxId);
    await tester.tap(find.text(s.chatSendRequest));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AddFriendForm), findsNothing);
    expect(h.service.outgoingFriendRequests, [kPeerToxId]);
    handle.dispose();
  });

  testWidgets(
    'short phone with the keyboard up: the send button stays reachable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 560);
      tester.view.devicePixelRatio = 1.0;
      // A soft keyboard covering the lower half of the screen.
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final h = ChatHarness();
      addTearDown(h.dispose);
      await tester.pumpWidget(
        h.wrap(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showAddFriendSheet(
                    context,
                    service: h.service,
                    canScan: true,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull); // no RenderFlex overflow
      final send = find.text(s.chatSendRequest);
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, kPeerToxId);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(h.service.outgoingFriendRequests, [kPeerToxId]);
    },
  );
}
