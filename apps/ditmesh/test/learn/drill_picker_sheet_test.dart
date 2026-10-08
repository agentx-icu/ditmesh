import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/training/receive_session.dart';
import 'package:ditmesh/ui/learn/receive/drill_picker_sheet.dart';

const List<ReceiveDrillKind> _all = <ReceiveDrillKind>[
  ReceiveDrillKind.groups,
  ReceiveDrillKind.characters,
  ReceiveDrillKind.words,
  ReceiveDrillKind.abbreviations,
  ReceiveDrillKind.numbers,
  ReceiveDrillKind.callsigns,
  ReceiveDrillKind.confusables,
  ReceiveDrillKind.qso,
  ReceiveDrillKind.contest,
];

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('every drill has a distinct label and hint in every locale', (
    tester,
  ) async {
    for (final locale in S.supportedLocales) {
      final s = lookupS(locale);
      final labels = ReceiveDrillKind.values.map((k) => drillLabel(s, k));
      expect(labels.toSet(), hasLength(ReceiveDrillKind.values.length));
      final hints = ReceiveDrillKind.values.map((k) => drillDescription(s, k));
      expect(hints.toSet(), hasLength(ReceiveDrillKind.values.length));
    }
  });

  for (final locale in S.supportedLocales) {
    testWidgets('the sheet scrolls and returns the pick in $locale', (
      tester,
    ) async {
      await _setSize(tester, const Size(320, 568));
      final s = lookupS(locale);
      (ReceiveDrillKind, RadioPreset)? picked;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: locale,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async =>
                      picked = await showDrillPickerSheet(context, _all),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(s.learnChooseDrill), findsOneWidget);

      final last = find.byKey(
        DrillPickerList.tileKey(ReceiveDrillKind.contest),
      );
      await tester.scrollUntilVisible(
        last,
        100,
        scrollable: find.descendant(
          of: find.byType(DrillPickerList),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(s.learnDrillContestHint), findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(picked, (ReceiveDrillKind.contest, RadioPreset.clear));
    });
  }

  testWidgets('a conditions preset comes back with the pick; review is clean '
      'only', (tester) async {
    // Tall enough that every row is built.
    await _setSize(tester, const Size(800, 2400));
    (ReceiveDrillKind, RadioPreset)? picked;
    final previews = <RadioPreset>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => picked = await showDrillPickerSheet(
                  context,
                  [..._all, ReceiveDrillKind.review],
                  onPreview: (p) async => previews.add(p),
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
    // Clear: no preview to offer, review listed.
    expect(find.byKey(const Key('drill-conditions-preview')), findsNothing);
    expect(find.byKey(DrillPickerList.tileKey(ReceiveDrillKind.review)), findsOneWidget);
    await tester.tap(find.byKey(const Key('drill-conditions-radio')));
    await tester.pumpAndSettle();
    expect(find.byKey(DrillPickerList.tileKey(ReceiveDrillKind.review)), findsNothing);
    await tester.tap(find.byKey(const Key('drill-conditions-preview')));
    await tester.pumpAndSettle();
    expect(previews, [RadioPreset.radio]);
    await tester.tap(find.byKey(DrillPickerList.tileKey(ReceiveDrillKind.groups)));
    await tester.pumpAndSettle();
    expect(picked, (ReceiveDrillKind.groups, RadioPreset.radio));
  });
}
