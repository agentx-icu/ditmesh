import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/contacts/add_friend_sheet.dart';
import 'package:ditmesh/ui/contacts/qr_scan_page.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'crawl_health.dart';
import 'known_destinations.dart';
import 'layout_profiles.dart';
import 'plugin_host.dart';
import 'seeded_app.dart';

void main() {
  testWidgets('broken destination fails the same crawler health gate', (
    tester,
  ) async {
    final health = CrawlHealth(scene: () => 'broken destination');
    await health.capture(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (_) => throw StateError('destination failed')),
        ),
      );
      health.checkTree(tester);
    });
    expect(health.other, contains(contains('destination failed')));
    expect(health.other, contains(contains('visible ErrorWidget')));
    expect(health.requireHealthy, throwsA(isA<TestFailure>()));
  });

  test('stray asynchronous errors fail the same crawler health gate', () async {
    final health = CrawlHealth(scene: () => 'async destination');
    await health.capture(() async {
      scheduleMicrotask(() => throw StateError('async host failure'));
      await Future<void>.value();
    });
    expect(health.other.single, contains('async host failure'));
    expect(health.other.single, contains('plugin_host_test.dart'));
    expect(health.requireHealthy, throwsA(isA<TestFailure>()));
  });

  testWidgets('a missing destination cannot count as a successful action', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Text('source only')));
    final paths = KnownLayoutDestinations(
      tester,
      settle: () => settleLayout(tester),
    );
    expect(() => paths.currentPage(QrScanPage), throwsA(isA<TestFailure>()));
  });

  testWidgets(
    'the host restores both platform singletons before another host',
    (tester) async {
      final scanner = MobileScannerPlatform.instance;
      final picker = FilePickerPlatform.instance;
      final first = LayoutPluginHost(tester);
      expect(MobileScannerPlatform.instance, same(first.scanner));
      expect(FilePickerPlatform.instance, same(first.picker));
      await first.close();
      expect(MobileScannerPlatform.instance, same(scanner));
      expect(FilePickerPlatform.instance, same(picker));
      final second = LayoutPluginHost(tester);
      expect(second.scanner, isNot(same(first.scanner)));
      await second.close();
      expect(MobileScannerPlatform.instance, same(scanner));
      expect(FilePickerPlatform.instance, same(picker));
    },
  );

  testWidgets('root-navigator key editor uses an owned injected sink', (
    tester,
  ) async {
    applyProfile(tester, profileNamed('desktop'));
    final host = LayoutPluginHost(tester);
    await pumpSeededApp(tester, plugins: host);
    final paths = KnownLayoutDestinations(
      tester,
      settle: () => settleLayout(tester),
    );
    await paths.keyEditor();
    expect(host.sinks, hasLength(1));
    expect(host.sinks.single.prepareCalls, 1);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(host.sinks.single.isOn, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(seconds: 1));
    expect(host.sinks.single.isOn, isFalse);
    await paths.root();
    expect(host.sinks.single.disposeCalls, 1);
    await paths.keyEditor();
    expect(host.sinks, hasLength(2));
    expect(host.sinks.last, isNot(same(host.sinks.first)));
  });

  testWidgets('root-navigator recording accepts a WAV and plays on fake', (
    tester,
  ) async {
    applyProfile(tester, profileNamed('desktop'));
    final host = LayoutPluginHost(tester);
    await pumpSeededApp(tester, plugins: host);
    final paths = KnownLayoutDestinations(
      tester,
      settle: () => settleLayout(tester),
    );
    await paths.recording();
    expect(host.picker.calls, 1);
    expect(host.players, hasLength(1));
    await paths.tap(find.byKey(const ValueKey('workbench-play')));
    expect(host.players.single.plays, hasLength(1));
    await paths.root();
    expect(host.players.single.disposed, isTrue);
  });

  testWidgets('scanner builds then returns only a valid ID to the same form', (
    tester,
  ) async {
    applyProfile(tester, profileNamed('phone'));
    final host = LayoutPluginHost(tester);
    await pumpSeededApp(tester, plugins: host);
    final paths = KnownLayoutDestinations(
      tester,
      settle: () => settleLayout(tester),
    );
    await paths.scanner();
    expect(host.scanner.starts, 1);
    host.scanner.detect('not a Tox ID');
    await settleLayout(tester);
    expect(find.byType(QrScanPage), findsOneWidget);
    final id = FakeIdentityService.toxIdForSeed(900);
    host.scanner.detect(id);
    await settleLayout(tester);
    expect(find.byType(QrScanPage), findsNothing);
    expect(find.byType(AddFriendForm), findsOneWidget);
    expect(find.widgetWithText(TextFormField, id), findsOneWidget);
    await paths.root();
    expect(host.scanner.disposals, 1);
  });

  testWidgets(
    'recording cancellation remains empty and is not import evidence',
    (tester) async {
      applyProfile(tester, profileNamed('desktop'));
      final host = LayoutPluginHost(tester)..picker.cancel = true;
      await pumpSeededApp(tester, plugins: host);
      await KnownLayoutDestinations(
        tester,
        settle: () => settleLayout(tester),
      ).recording(cancel: true);
      expect(host.picker.calls, 1);
      expect(host.players.single.plays, isEmpty);
    },
  );
}
