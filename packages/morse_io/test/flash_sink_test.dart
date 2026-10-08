import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

final class _FakeTorch implements TorchApi {
  _FakeTorch({this.available = true});

  final bool available;
  final List<String> calls = <String>[];

  @override
  Future<bool> isAvailable() async {
    calls.add('isAvailable');
    return available;
  }

  @override
  Future<void> enable() async => calls.add('enable');

  @override
  Future<void> disable() async => calls.add('disable');
}

void main() {
  test('listenable flips synchronously on every platform', () async {
    final sink = FlashSink(platformOverride: TargetPlatform.windows);
    final seen = <bool>[];
    sink.isOn.addListener(() => seen.add(sink.isOn.value));
    await sink.prepare();
    sink.on();
    sink.on();
    sink.off();
    expect(seen, <bool>[true, false]);
    expect(sink.torchActive, isFalse);
    await sink.dispose();
  });

  test('torch follows the key on mobile when requested and available',
      () async {
    final torch = _FakeTorch();
    final sink = FlashSink(
      useTorch: true,
      torchApi: torch,
      platformOverride: TargetPlatform.android,
    );
    await sink.prepare();
    expect(sink.torchActive, isTrue);
    sink.on();
    sink.off();
    await Future<void>.delayed(Duration.zero);
    expect(torch.calls, <String>['isAvailable', 'enable', 'disable']);
    await sink.dispose();
  });

  test('torch is not probed on desktop even when requested', () async {
    final torch = _FakeTorch();
    final sink = FlashSink(
      useTorch: true,
      torchApi: torch,
      platformOverride: TargetPlatform.macOS,
    );
    await sink.prepare();
    sink.on();
    sink.off();
    expect(sink.torchActive, isFalse);
    expect(torch.calls, isEmpty);
    await sink.dispose();
  });

  test('unavailable torch degrades to screen flash only', () async {
    final torch = _FakeTorch(available: false);
    final sink = FlashSink(
      useTorch: true,
      torchApi: torch,
      platformOverride: TargetPlatform.iOS,
    );
    await sink.prepare();
    sink.on();
    expect(sink.isOn.value, isTrue);
    expect(torch.calls, <String>['isAvailable']);
    await sink.dispose();
  });

  test('dispose turns the flash off first', () async {
    final torch = _FakeTorch();
    final sink = FlashSink(
      useTorch: true,
      torchApi: torch,
      platformOverride: TargetPlatform.android,
    );
    await sink.prepare();
    sink.on();
    await sink.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(torch.calls.last, 'disable');
  });
}
