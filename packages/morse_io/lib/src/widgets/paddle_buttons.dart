import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../clock.dart';
import '../iambic_keyer.dart';
import '../keyboard_binding.dart';

/// Two side-by-side paddles (dit left, dah right by default) driving a
/// [PaddleInput] such as [IambicKeyer].
///
/// Each paddle tracks its own pointer ids, so both can be held at once with
/// two fingers (a squeeze) and a paddle only releases when its last finger
/// lifts. Keyboard keys bound to [KeyerAction.dit] / [KeyerAction.dah] in
/// [binding] work while the widget has focus; repeats are ignored. Losing
/// focus releases any keyboard-held paddle (the key-up goes to whatever took
/// focus), and touching a paddle takes focus back. Leaving the foreground
/// releases both paddles (on mobile focus survives backgrounding, but the
/// key-up and pointer-up never arrive).
///
/// Accessibility: each paddle exposes a semantic tap that presses and
/// releases it, which the keyer turns into one element (its paddle memory
/// keeps a tap shorter than an element).
class PaddleButtons extends StatefulWidget {
  PaddleButtons({
    super.key,
    required this.input,
    Clock? clock,
    KeyboardKeyBinding? binding,
    bool keyboard = true,
    this.height = 160,
    this.gap = 12,
    this.swapPaddles = false,
    this.autofocus = false,
    this.ditLabel = 'DIT',
    this.dahLabel = 'DAH',
  }) : clock = clock ?? SystemClock.shared,
       binding = keyboard ? (binding ?? KeyboardKeyBinding.defaults) : null;

  static const double minTouchTarget = 48;

  final PaddleInput input;
  final Clock clock;
  final KeyboardKeyBinding? binding;
  final double height;
  final double gap;

  /// Put dah on the left (left-handed layout). Keyboard mapping is unchanged.
  final bool swapPaddles;
  final bool autofocus;
  final String ditLabel;
  final String dahLabel;

  @override
  State<PaddleButtons> createState() => _PaddleButtonsState();
}

class _PaddleButtonsState extends State<PaddleButtons>
    with WidgetsBindingObserver {
  final FocusNode _focus = FocusNode(debugLabel: 'PaddleButtons');
  final _PaddleState _dit = _PaddleState();
  final _PaddleState _dah = _PaddleState();

  void _sync(_PaddleState paddle, bool isDit) {
    // See StraightKeyButton: late pointer events after dispose are dropped.
    if (!mounted) {
      return;
    }
    final down = paddle.isDown;
    if (down == paddle.reported) {
      return;
    }
    paddle.reported = down;
    final at = widget.clock.now();
    if (isDit) {
      widget.input.ditPaddle(down, at);
    } else {
      widget.input.dahPaddle(down, at);
    }
    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final action = widget.binding?.actionFor(event.logicalKey);
    final paddle = switch (action) {
      KeyerAction.dit => _dit,
      KeyerAction.dah => _dah,
      _ => null,
    };
    if (paddle == null) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      paddle.keyboardDown = true;
      _sync(paddle, paddle == _dit);
    } else if (event is KeyUpEvent) {
      paddle.keyboardDown = false;
      _sync(paddle, paddle == _dit);
    }
    return KeyEventResult.handled;
  }

  void _onFocusChange(bool focused) {
    if (focused) {
      return;
    }
    for (final paddle in <_PaddleState>[_dit, _dah]) {
      if (paddle.keyboardDown) {
        paddle.keyboardDown = false;
        _sync(paddle, paddle == _dit);
      }
    }
  }

  /// One press-and-release, as a screen reader's activation.
  void _semanticTap(bool isDit) {
    final at = widget.clock.now();
    final paddle = isDit ? _dit : _dah;
    if (paddle.reported) {
      return;
    }
    if (isDit) {
      widget.input
        ..ditPaddle(true, at)
        ..ditPaddle(false, at);
    } else {
      widget.input
        ..dahPaddle(true, at)
        ..dahPaddle(false, at);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    for (final paddle in [_dit, _dah]) {
      if (!paddle.isDown) continue;
      paddle
        ..keyboardDown = false
        ..pointers.clear();
      _sync(paddle, paddle == _dit);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    final at = widget.clock.now();
    if (_dit.reported) {
      widget.input.ditPaddle(false, at);
    }
    if (_dah.reported) {
      widget.input.dahPaddle(false, at);
    }
    super.dispose();
  }

  Widget _paddle(_PaddleState state, bool isDit) => Expanded(
    child: _Paddle(
      label: isDit ? widget.ditLabel : widget.dahLabel,
      down: state.isDown,
      height: widget.height < PaddleButtons.minTouchTarget
          ? PaddleButtons.minTouchTarget
          : widget.height,
      onPointerDown: (event) {
        if (widget.binding != null && !_focus.hasFocus) _focus.requestFocus();
        state.pointers.add(event.pointer);
        _sync(state, isDit);
      },
      onPointerUp: (event) {
        state.pointers.remove(event.pointer);
        _sync(state, isDit);
      },
      onSemanticTap: () => _semanticTap(isDit),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final left = _paddle(widget.swapPaddles ? _dah : _dit, !widget.swapPaddles);
    final right = _paddle(widget.swapPaddles ? _dit : _dah, widget.swapPaddles);
    // Android gesture navigation owns a back-gesture zone on both screen
    // edges (`systemGestureInsets.left/right`, ~30 dp). A press that starts
    // there and drifts inward is taken by the system as "back" and the paddle
    // only sees a cancel, so the pads stay out of those zones. SafeArea does
    // not remove gesture insets, and the widget cannot know its distance to
    // the edge, so the inset is applied in full; it is zero where there is no
    // gesture navigation (iOS, 3-button Android, desktop).
    final EdgeInsets gestures =
        MediaQuery.maybeSystemGestureInsetsOf(context) ?? EdgeInsets.zero;
    return Focus(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onKeyEvent: widget.binding == null ? null : _onKey,
      onFocusChange: _onFocusChange,
      child: Padding(
        padding: EdgeInsets.only(left: gestures.left, right: gestures.right),
        child: Row(
          children: <Widget>[
            left,
            SizedBox(width: widget.gap),
            right,
          ],
        ),
      ),
    );
  }
}

class _PaddleState {
  final Set<int> pointers = <int>{};
  bool keyboardDown = false;
  bool reported = false;

  bool get isDown => pointers.isNotEmpty || keyboardDown;
}

class _Paddle extends StatelessWidget {
  const _Paddle({
    required this.label,
    required this.down,
    required this.height,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onSemanticTap,
  });

  final String label;
  final bool down;
  final double height;
  final void Function(PointerDownEvent) onPointerDown;
  final void Function(PointerEvent) onPointerUp;
  final VoidCallback onSemanticTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: label,
      onTap: onSemanticTap,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: onPointerDown,
        onPointerUp: onPointerUp,
        onPointerCancel: onPointerUp,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: down ? scheme.primary : scheme.primaryContainer,
              shape:
                  theme.outlinedButtonTheme.style?.shape?.resolve({}) ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
            ),
            child: Center(
              // The button's semantics carry the label; the printed text
              // must not be announced a second time.
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: down ? scheme.onPrimary : scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
