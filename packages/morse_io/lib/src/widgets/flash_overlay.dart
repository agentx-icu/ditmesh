import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A bounded light indicator following [isOn], without covering page content.
/// Reduced-motion users receive a steady indicator, with no key-rate flashing.
class FlashOverlay extends StatelessWidget {
  const FlashOverlay({
    super.key,
    required this.isOn,
    this.onColor,
    this.offColor = const Color(0x00000000),
    this.child,
  });

  final ValueListenable<bool> isOn;
  final Color? onColor;
  final Color offColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dark =
        MediaQuery.maybeOf(context)?.platformBrightness == Brightness.dark;
    final color =
        onColor ?? (dark ? const Color(0xFF827C60) : const Color(0xFF706B50));
    Widget lamp(Color fill) =>
        SizedBox(width: 24, height: 24, child: ColoredBox(color: fill));
    final indicator = IgnorePointer(
      child: reduced
          ? lamp(color)
          : ValueListenableBuilder<bool>(
              valueListenable: isOn,
              builder: (context, on, _) => lamp(on ? color : offColor),
            ),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ?child,
        Positioned(top: 8, right: 8, child: indicator),
      ],
    );
  }
}
