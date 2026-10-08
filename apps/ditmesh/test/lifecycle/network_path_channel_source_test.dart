// Pins the contract of the Android default-network watcher
// (android/app/src/main/kotlin/icu/agentx/ditmesh/NetworkPathChannel.kt) to
// its source text. The Kotlin side has no JVM test harness in this
// repository: `NetworkCapabilities` and `Network` are final Android classes
// that cannot be constructed off-device without Robolectric, which is not a
// dependency. What matters to the Dart policy in
// lib/lifecycle/network_change_rebootstrapper.dart is WHAT goes into the
// identity string, and that is checkable here (checklist N3, N4, N6).
//
// Runs with the package root (apps/ditmesh) as the working directory.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String source = File(
    'android/app/src/main/kotlin/icu/agentx/ditmesh/NetworkPathChannel.kt',
  ).readAsStringSync();

  /// Body of the top-level `private fun <name>(` in [source], up to the next
  /// member declaration.
  String member(String name) {
    final start = source.indexOf('private fun $name(');
    expect(start, isNonNegative, reason: 'fun $name missing');
    final rest = source.substring(start + 1);
    final end = RegExp(
      r'\n    (private |override |/\*\*|companion object)',
    ).firstMatch(rest);
    return rest.substring(0, end?.start ?? rest.length);
  }

  test('N4: the identity never includes the signal strength', () {
    // `onCapabilitiesChanged` fires on every signal-strength step; a burst of
    // them must collapse to ONE identity (`emit` drops equal snapshots).
    expect(source.toLowerCase(), isNot(contains('signalstrength')));
    expect(source, contains('if (snapshot == lastSent) return'));
    final identity = member('identity');
    expect(identity, contains('hasTransport'));
    expect(identity, contains('linkAddresses'));
  });

  test('N3: validated Internet is part of the identity', () {
    // Captive portal: same network handle and addresses before and after the
    // login; only NET_CAPABILITY_VALIDATED flips. Without it in the identity
    // the post-login re-bootstrap never fires.
    final identity = member('identity');
    expect(identity, contains('NET_CAPABILITY_VALIDATED'));
    // And `available` keeps Android's meaning (a default network exists), so
    // an unvalidated-but-usable network still receives kicks on real changes.
    final emit = member('emit');
    expect(emit, contains('val available = defaultNetwork != null'));
    expect(emit, isNot(contains('VALIDATED')));
  });

  test('N6: only the API 24+ default-network callback exists', () {
    // minSdk is `flutter.minSdkVersion` = 24; an API 23 branch would be
    // unreachable and untested.
    expect(source, contains('cm.registerDefaultNetworkCallback(cb)'));
    expect(source, isNot(contains('listenApi23')));
    expect(source, isNot(contains('SDK_INT')));
    expect(source, isNot(contains('registerNetworkCallback(request')));
    expect(source, isNot(contains('import android.os.Build')));
  });
}
