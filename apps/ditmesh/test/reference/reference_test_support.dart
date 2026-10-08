import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/reference/reference_player.dart';

/// A [MorsePlayerFactory] for widget tests: every player it builds shares
/// one [FakeClock] and one [RecordingSink], so a test can advance time
/// deterministically and inspect what would have sounded.
final class FakeReferencePlayer {
  FakeReferencePlayer({FakeClock? clock}) : clock = clock ?? FakeClock() {
    sink = RecordingSink(clock: this.clock);
  }

  final FakeClock clock;
  late final RecordingSink sink;

  /// Players created so far, newest last.
  final List<MorsePlayer> players = <MorsePlayer>[];

  MorsePlayer create() {
    final MorsePlayer player = MorsePlayer(sink: sink, clock: clock);
    attachReferenceSink(player, sink);
    players.add(player);
    return player;
  }

  /// Number of key-down transitions the sink saw.
  int get onCount => sink.events.where((e) => e.on).length;
}

/// Sizes the test surface: a phone in portrait by default.
void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const Size kPhone = Size(390, 844);
const Size kDesktop = Size(1280, 800);

/// The locale the widget tests run in, and its strings for expectations.
const Locale kTestLocale = Locale('en');
final S kTestStrings = lookupS(kTestLocale);

/// Pumps [home] inside a localised `MaterialApp` and settles.
Future<void> pumpScreen(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: kTestLocale,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
