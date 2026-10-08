import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Paints the whole area a solid [onColor] while [isOn] is true.
///
/// Feed it `FlashSink.isOn`. Wrap your page in it (with [child]) or drop it
/// in a [Stack]; it ignores pointers so it never steals taps from the keys
/// underneath. Works identically on every platform.
class FlashOverlay extends StatelessWidget {
  const FlashOverlay({
    super.key,
    required this.isOn,
    this.onColor = const Color(0xFFFFFFFF),
    this.offColor = const Color(0x00000000),
    this.child,
  });

  final ValueListenable<bool> isOn;
  final Color onColor;
  final Color offColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final flash = IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: isOn,
        builder: (context, on, _) => ColoredBox(color: on ? onColor : offColor),
      ),
    );
    final body = child;
    if (body == null) {
      return flash;
    }
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        body,
        Positioned.fill(child: flash),
      ],
    );
  }
}
