import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../responsive.dart';

/// The send screen's "copy from memory" switch for the app bar.
///
/// Keeps the written label whenever the title, other actions, label and
/// switch fit the bar at the current language and text size; a narrow
/// phone or large text falls back to an icon (decided by [labelFits]). The
/// tooltip and merged semantics keep the switch named for screen readers
/// either way.
class CopyFromMemorySwitch extends StatelessWidget {
  const CopyFromMemorySwitch({
    super.key,
    required this.showLabel,
    required this.value,
    required this.onChanged,
  });

  /// Whether the written label fits; see [labelFits].
  final bool showLabel;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Whether [title], [extraActions] icon buttons and the labelled switch
  /// fit one app bar row. Call it with the screen's context: inside the
  /// AppBar its SafeArea has already removed the notch insets.
  static bool labelFits(
    BuildContext context, {
    required String title,
    int extraActions = 0,
  }) =>
      _appBarFits(context, title, context.s.learnCopyFromMemory, extraActions);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final roomForLabel = showLabel;
    return MergeSemantics(
      child: Tooltip(
        message: s.learnCopyFromMemory,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (roomForLabel)
              Text(s.learnCopyFromMemory, maxLines: 1)
            else
              Semantics(
                label: s.learnCopyFromMemory,
                child: const Icon(Icons.visibility_off_outlined),
              ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  /// Whether [title] plus the [label] + switch action (and any extra icon
  /// buttons) fit one app bar row inside the horizontal safe area (a
  /// landscape notch takes ~47 pt per side): back button, title spacing,
  /// the 60 px switch and the trailing gap are fixed chrome.
  static bool _appBarFits(
    BuildContext context,
    String title,
    String label,
    int extraActions,
  ) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    // The AppBar clamps the title's text scale; actions scale freely.
    double width(String text, TextStyle? style, {bool title = false}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: title
            ? appBarTitleTextScaler(media.textScaler)
            : media.textScaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    const chrome = kToolbarHeight + NavigationToolbar.kMiddleSpacing * 2 + 68;
    final needed =
        chrome +
        extraActions * kMinInteractiveDimension +
        width(
          title,
          theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
          title: true,
        ) +
        width(
          label,
          theme.appBarTheme.toolbarTextStyle ?? theme.textTheme.bodyMedium,
        );
    return needed <= media.size.width - media.padding.horizontal;
  }
}
