import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

void main() {
  testWidgets('reports background on mobile and inactive as foreground', (
    tester,
  ) async {
    const foreground = BindingAppForeground(
      platformOverride: TargetPlatform.iOS,
    );
    final seen = <bool>[];
    final cancel = foreground.listen(seen.add);
    addTearDown(cancel);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(foreground.isForeground, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(foreground.isForeground, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(seen, <bool>[true, false, false, false, true, true]);
  });

  testWidgets('desktop always reports foreground', (tester) async {
    const foreground = BindingAppForeground(
      platformOverride: TargetPlatform.macOS,
    );
    final seen = <bool>[];
    final cancel = foreground.listen(seen.add);
    addTearDown(cancel);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(foreground.isForeground, isTrue);
    expect(seen, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
