// Opt-in native camera and acoustic playback/capture verification.
// Run with flutter test integration_test/manual/media_device_test.dart -d macos
// --dart-define=DITMESH_MEDIA_DEVICE_TEST=true.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/contacts/add_friend_sheet.dart';
import 'package:ditmesh/ui/contacts/qr_scan_page.dart';
import 'package:ditmesh/ui/listen/record_pcm_source.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_controller.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:morse_dsp/morse_dsp.dart';
import 'package:morse_io/morse_io.dart';

const _enabled = bool.fromEnvironment('DITMESH_MEDIA_DEVICE_TEST');
const _qrAddress = String.fromEnvironment('DITMESH_MEDIA_QR_ADDRESS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the contact scanner opens and closes the native preview', (
    tester,
  ) async {
    final service = FakeChatService();
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showAddFriendSheet(context, service: service),
              child: const Text('Open add contact'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open add contact'));
    await tester.pumpAndSettle();
    final strings = S.of(tester.element(find.byType(AddFriendForm)));
    final scan = find.text(strings.chatScanQr);
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pump();
    expect(find.byType(QrScanPage), findsOneWidget);
    final camera = find.byType(MobileScanner);
    final preview = find.descendant(of: camera, matching: find.byType(Texture));
    final cameraError = find.descendant(
      of: camera,
      matching: find.byType(QrScanErrorView),
    );
    await _waitFor(
      tester,
      () => preview.evaluate().isNotEmpty,
      reason: 'Native camera preview did not start.',
    );
    expect(cameraError, findsNothing);
    debugPrint('MEDIA_CAMERA_EVIDENCE preview=true');

    if (_qrAddress.isEmpty) {
      await tester.pageBack();
    } else {
      await _waitFor(
        tester,
        () => find.byType(QrScanPage).evaluate().isEmpty,
        timeout: const Duration(minutes: 2),
        reason: 'The expected QR code did not close the scanner.',
      );
      final values = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((field) => field.controller.text);
      expect(values, contains(_qrAddress));
      expect(service.outgoingFriendRequests, isEmpty);
      debugPrint('MEDIA_CAMERA_EVIDENCE toxQrPopulated=true');
    }
    await tester.pumpAndSettle();
    expect(preview, findsNothing);
    expect(find.byType(AddFriendForm), findsOneWidget);
  }, skip: !_enabled);

  testWidgets(
    'the system microphone captures the tone played by the speaker',
    (tester) async {
      const sampleRate = 48000;
      const toneHz = 731.0;
      const length = Duration(seconds: 2);
      final source = RecordPcmSource();
      final detector = GoertzelDetector(
        frequencyHz: toneHz,
        sampleRate: sampleRate,
      );
      final player = SoloudClipPlayer();
      addTearDown(player.dispose);
      try {
        expect(await source.hasPermission(), isTrue);
        final pcm = await source.start(sampleRate: sampleRate, channels: 1);
        var peakPower = 0.0;
        var chunks = 0;
        final recording = pcm.listen((bytes) {
          chunks++;
          peakPower = math.max(
            peakPower,
            detector.powerInt16(Pcm.int16FromBytes(bytes)),
          );
        });
        addTearDown(recording.cancel);
        await Future<void>.delayed(const Duration(seconds: 1));
        expect(chunks, greaterThan(0));
        final roomPower = peakPower;
        peakPower = 0;
        final samples = Float64List(sampleRate * length.inSeconds);
        for (var i = 0; i < samples.length; i++) {
          samples[i] = 0.25 * math.sin(2 * math.pi * toneHz * i / sampleRate);
        }
        await player.play(
          WorkbenchController.monoWav(samples, sampleRate),
          length: length,
        );
        expect(player.isPlaying, isTrue);
        await Future<void>.delayed(length);
        final playingPower = peakPower;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(player.isPlaying, isFalse);
        peakPower = 0;
        await Future<void>.delayed(const Duration(seconds: 1));
        final stoppedPower = peakPower;
        expect(
          playingPower,
          greaterThan(math.max(roomPower, stoppedPower) * 10 + 1e-10),
          reason:
              '731 Hz power before=$roomPower, during=$playingPower, '
              'after=$stoppedPower',
        );
        debugPrint(
          'MEDIA_AUDIO_EVIDENCE 731Hz '
          'before=$roomPower during=$playingPower after=$stoppedPower',
        );
      } finally {
        try {
          await source.stop();
        } finally {
          await source.dispose();
        }
      }
    },
    skip: !_enabled,
  );
}

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() ready, {
  Duration timeout = const Duration(seconds: 30),
  required String reason,
}) async {
  final elapsed = Stopwatch()..start();
  while (!ready() && elapsed.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue, reason: reason);
}
