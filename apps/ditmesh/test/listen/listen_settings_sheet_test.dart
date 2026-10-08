import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/listen/listen_settings.dart';

import '../learn/helpers/l10n.dart';

Future<List<ListenSettings>> _pump(
  WidgetTester tester, {
  ListenSettings settings = const ListenSettings(),
  int sampleRate = 48000,
}) async {
  final List<ListenSettings> changes = <ListenSettings>[];
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    l10nApp(
      home: Scaffold(
        body: ListenSettingsSheet(
          settings: settings,
          sampleRate: sampleRate,
          onChanged: changes.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return changes;
}

void main() {
  group('ListenSettings', () {
    test('value semantics and copyWith', () {
      const ListenSettings a = ListenSettings();
      final ListenSettings b = a.copyWith();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      final ListenSettings c = a.copyWith(blockSize: 512, autoTune: false);
      expect(c.blockSize, 512);
      expect(c.autoTune, isFalse);
      expect(c.minElementMs, a.minElementMs);
      expect(c.manualHz, a.manualHz);
      expect(c, isNot(a));
      expect(a.copyWith(manualHz: 650), isNot(a));
    });

    test('blockMs follows the sample rate', () {
      expect(const ListenSettings().blockMs(48000), closeTo(5.33, 0.01));
      expect(const ListenSettings(blockSize: 512).blockMs(16000), 32);
    });
  });

  group('ListenSettingsSheet', () {
    testWidgets('renders the current values', (tester) async {
      await _pump(tester);
      expect(find.text(en.listenSettings), findsOneWidget);
      expect(find.text(en.listenAutoTune), findsOneWidget);
      expect(find.text(en.listenBlockSize), findsOneWidget);
      expect(find.text(en.listenMsValue(12)), findsNWidgets(1));
      expect(
        find.textContaining(en.listenBlockSamples(256, '5.3')),
        findsOneWidget,
      );
      for (final int size in ListenSettings.blockSizes) {
        expect(find.text('$size'), findsOneWidget);
      }
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('toggling auto-tune reports at once', (tester) async {
      final List<ListenSettings> changes = await _pump(tester);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(changes.single.autoTune, isFalse);
      expect(changes.single.blockSize, 256, reason: 'other fields untouched');
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
    });

    testWidgets('picking a block size reports and updates the readout', (
      tester,
    ) async {
      final List<ListenSettings> changes = await _pump(tester);
      await tester.tap(find.text('512'));
      await tester.pumpAndSettle();
      expect(changes.single.blockSize, 512);
      expect(
        find.textContaining(en.listenBlockSamples(512, '10.7')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
            .selected,
        <int>{512},
      );
    });

    testWidgets('the debounce slider previews while dragging and reports on release', (
      tester,
    ) async {
      final List<ListenSettings> changes = await _pump(tester);
      final Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, ListenSettings.minElementMinMs.toDouble());
      expect(slider.max, ListenSettings.minElementMaxMs.toDouble());
      slider.onChanged!(20.4);
      await tester.pump();
      expect(changes, isEmpty, reason: 'no commit mid-drag');
      expect(find.text(en.listenMsValue(20)), findsOneWidget);
      slider.onChangeEnd!(20.4);
      await tester.pump();
      expect(changes.single.minElementMs, 20);
    });

    testWidgets('an out-of-range initial debounce is clamped on the slider', (
      tester,
    ) async {
      await _pump(tester, settings: const ListenSettings(minElementMs: 99));
      final Slider slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, ListenSettings.minElementMaxMs.toDouble());
      expect(slider.value, lessThanOrEqualTo(slider.max));
      expect(slider.value, greaterThanOrEqualTo(slider.min));
    });
  });
}
