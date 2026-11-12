import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';

void main() {
  testWidgets(
    'chat keying does not vibrate before an enabled preference is loaded',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => calls.add(call),
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      final playback = MorsePlaybackController();
      addTearDown(playback.dispose);
      playback.keyingSink.on();
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
      playback.keyingSink.off();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
