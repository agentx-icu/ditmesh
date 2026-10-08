import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_dsp/testing.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/listen/listen_controller.dart';
import 'package:ditmesh/ui/listen/listen_screen.dart';
import 'package:ditmesh/ui/listen/listen_widgets.dart';
import 'package:ditmesh/ui/listen/listen_preferences.dart';
import 'package:provider/provider.dart';

import 'fake_pcm_source.dart';

/// Strings of the locale the harness pins.
final S en = lookupS(const Locale('en'));
final S zh = lookupS(const Locale('zh'));

Future<void> _pump(
  WidgetTester tester,
  FakePcmSource source, {
  ListenPreferences? preferences,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,
      home: preferences == null
          ? ListenScreen(source: source)
          : ChangeNotifierProvider<ListenPreferences>.value(
              value: preferences,
              child: ListenScreen(source: source),
            ),
    ),
  );
  await tester.pumpAndSettle();
}

String _decodedText(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(ListenScreen.decodedTextKey))
    .data!
    .trim();

/// English platform text that must never reach the UI.
const String _rawDetail = 'No input device: AVAudioSession error -50';

void _pushText(FakePcmSource source, String text, {double wpm = 20}) {
  final pcm = SyntheticMorse(snrDb: 20).renderText(text, wpm: wpm);
  for (final chunk in SyntheticMorse.toByteChunks(pcm, 960)) {
    source.push(chunk);
  }
}

void main() {
  testWidgets('manual tuning and retune update the persisted preferences', (
    tester,
  ) async {
    final preferences = ListenPreferences();
    addTearDown(preferences.dispose);
    await _pump(tester, FakePcmSource(), preferences: preferences);
    final slider = find.byType(Slider).first;
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.left + rect.width * 0.9, rect.center.dy));
    await tester.pumpAndSettle();
    expect(preferences.settings.autoTune, isFalse);
    expect(preferences.settings.manualHz, greaterThan(800));
    await tester.tap(find.text(en.listenRetune));
    await tester.pumpAndSettle();
    expect(preferences.settings.autoTune, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('decodes synthetic PCM from the source into the text panel', (
    tester,
  ) async {
    final source = FakePcmSource();
    await _pump(tester, source);
    expect(find.text(en.listenStart), findsOneWidget);
    expect(find.text(en.listenIdleHint), findsOneWidget);

    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    expect(source.isStreaming, isTrue);
    expect(source.lastSampleRate, 48000);
    expect(source.lastChannels, 1);
    expect(find.text(en.listenStop), findsOneWidget);
    expect(find.text(en.listenEmptyHint), findsOneWidget);

    _pushText(source, 'SOS');
    await tester.pump();
    expect(_decodedText(tester), 'SOS');
    expect(find.text(en.listenEmptyHint), findsNothing);
    expect(find.text(en.listenToneLocked), findsOneWidget);
    // Interpolated tune sits within a couple of Hz of 700 on a noisy tone
    // and the speed estimate carries ~1 ms of gate edge bias, so allow a
    // small band rather than the exact label.
    expect(
      find.textContaining(RegExp(r'^(69[5-9]|70[0-5]) Hz$')),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'^(19|20|21) WPM$')), findsOneWidget);

    await tester.tap(find.text(en.listenStop));
    await tester.pumpAndSettle();
    expect(source.isStreaming, isFalse);
    expect(source.stopCalls, 1);
    expect(find.text(en.listenStart), findsOneWidget);
    // Text survives stopping.
    expect(_decodedText(tester), 'SOS');
  });

  testWidgets('shows the permission-denied state and lets the user retry', (
    tester,
  ) async {
    final source = FakePcmSource(permissionGranted: false);
    await _pump(tester, source);
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    expect(find.text(en.listenPermissionDenied), findsOneWidget);
    expect(source.startCalls, 0);
    expect(find.text(en.listenStart), findsOneWidget);

    source.permissionGranted = true;
    await tester.tap(find.text(en.listenPermissionRetry));
    await tester.pumpAndSettle();
    expect(find.text(en.listenPermissionDenied), findsNothing);
    expect(source.isStreaming, isTrue);
  });

  for (final (Locale locale, S s) in <(Locale, S)>[
    (const Locale('en'), en),
    (const Locale('zh'), zh),
  ]) {
    testWidgets('reports a missing microphone without crashing ($locale)', (
      tester,
    ) async {
      final source = FakePcmSource(
        startError: StateError(_rawDetail),
        inputDevicePresent: false,
      );
      await _pump(tester, source, locale: locale);
      await tester.tap(find.text(s.listenStart));
      await tester.pumpAndSettle();
      expect(find.text(s.listenNoInput), findsOneWidget);
      expect(find.textContaining(_rawDetail), findsNothing);
      expect(source.isStreaming, isFalse);
      expect(find.text(s.listenStart), findsOneWidget);
    });

    testWidgets('a start failure shows only the localised message ($locale)', (
      tester,
    ) async {
      // Even text that looks like "no microphone" is not parsed.
      final source = FakePcmSource(startError: StateError(_rawDetail));
      await _pump(tester, source, locale: locale);
      await tester.tap(find.text(s.listenStart));
      await tester.pumpAndSettle();
      expect(find.text(s.listenStartFailed), findsOneWidget);
      expect(find.text(s.listenNoInput), findsNothing);
      expect(find.textContaining(_rawDetail), findsNothing);
      expect(find.text(s.listenPermissionRetry), findsOneWidget);
    });

    testWidgets('a permission query error is a start failure ($locale)', (
      tester,
    ) async {
      final source = FakePcmSource(permissionError: StateError(_rawDetail));
      await _pump(tester, source, locale: locale);
      await tester.tap(find.text(s.listenStart));
      await tester.pumpAndSettle();
      expect(find.text(s.listenStartFailed), findsOneWidget);
      expect(find.text(s.listenPermissionDenied), findsNothing);
      expect(find.textContaining(_rawDetail), findsNothing);
    });

    testWidgets('a stream error mid-capture is reported ($locale)', (
      tester,
    ) async {
      final source = FakePcmSource();
      await _pump(tester, source, locale: locale);
      await tester.tap(find.text(s.listenStart));
      await tester.pumpAndSettle();
      source.failStream(StateError(_rawDetail));
      await tester.pumpAndSettle();
      expect(find.text(s.listenStreamFailed), findsOneWidget);
      expect(find.text(s.listenStartFailed), findsNothing);
      expect(find.textContaining(_rawDetail), findsNothing);
      expect(source.isStreaming, isFalse);
      expect(find.text(s.listenStart), findsOneWidget);
    });
  }

  test('every failure kind maps to a localised string', () {
    for (final s in <S>[en, zh]) {
      expect(
        ListenStatusBanner.failureText(s, ListenFailureKind.permissionDenied),
        s.listenPermissionDenied,
      );
      expect(
        ListenStatusBanner.failureText(s, ListenFailureKind.noInputDevice),
        s.listenNoInput,
      );
      expect(
        ListenStatusBanner.failureText(s, ListenFailureKind.startFailed),
        s.listenStartFailed,
      );
      expect(
        ListenStatusBanner.failureText(s, ListenFailureKind.streamFailed),
        s.listenStreamFailed,
      );
    }
  });

  testWidgets('clear empties the text and copy puts it on the clipboard', (
    tester,
  ) async {
    final source = FakePcmSource();
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, source);
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    _pushText(source, 'CQ');
    await tester.pump();
    expect(_decodedText(tester), 'CQ');

    await tester.tap(find.byTooltip(en.listenCopy));
    await tester.pumpAndSettle();
    final clipboard = calls.where((c) => c.method == 'Clipboard.setData');
    expect(clipboard, hasLength(1));
    expect(
      (clipboard.single.arguments as Map<Object?, Object?>)['text'],
      startsWith('CQ'),
    );
    expect(find.text(en.listenCopied), findsOneWidget);

    await tester.tap(find.byTooltip(en.listenClear));
    await tester.pump();
    expect(_decodedText(tester), isEmpty);
  });

  testWidgets('stops capturing when the app goes to the background', (
    tester,
  ) async {
    final source = FakePcmSource();
    await _pump(tester, source);
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    expect(source.isStreaming, isTrue);

    // Walk the legal transition chain (AppLifecycleListener asserts on a
    // direct resumed -> paused or paused -> resumed jump).
    for (final state in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(source.isStreaming, isFalse);
    expect(source.stopCalls, 1);

    // Frames are not scheduled while paused; check the UI once visible again.
    for (final state in <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.text(en.listenStoppedInBackground), findsOneWidget);
    expect(find.text(en.listenStart), findsOneWidget);
    // Never resumes the microphone on its own.
    expect(source.isStreaming, isFalse);
  });

  testWidgets('dragging the tuning slider switches to manual', (tester) async {
    final source = FakePcmSource();
    await _pump(tester, source);
    expect(find.text(en.listenToneSearching), findsOneWidget);
    final slider = find.byType(Slider).first;
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.left + rect.width * 0.9, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text(en.listenToneManual), findsOneWidget);
    expect(find.text(en.listenRetune), findsOneWidget);

    await tester.tap(find.text(en.listenRetune));
    await tester.pumpAndSettle();
    expect(find.text(en.listenToneSearching), findsOneWidget);
  });

  testWidgets('disposing the screen stops and releases the source', (
    tester,
  ) async {
    final source = FakePcmSource();
    await _pump(tester, source);
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(source.isStreaming, isFalse);
    // The screen did not create the source, so it must not dispose it.
    expect(source.disposed, isFalse);
  });
}
