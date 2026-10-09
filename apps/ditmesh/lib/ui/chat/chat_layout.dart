import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';

/// At or above this width the chat and groups pages show the list and the
/// open conversation side by side; below it the conversation is pushed as a
/// route. Wider than the shell's 600 rail breakpoint on purpose: a 7" tablet
/// in portrait gets the rail but not two panes.
const double kMasterDetailMinWidth = 900;

bool isMasterDetailWidth(double width) => width >= kMasterDetailMinWidth;

bool isMasterDetail(BuildContext context) =>
    isMasterDetailWidth(MediaQuery.sizeOf(context).width);

/// Width of the list pane in master-detail mode.
const double kMasterPaneWidth = 360;

/// Touch-first platforms get swipe actions and QR scanning; desktop gets
/// right-click menus and a "needs a camera" hint instead.
bool get isTouchPlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Two-pane layout: [master] on the left at a fixed width, [detail] filling
/// the rest (or a neutral prompt when nothing is selected).
class MasterDetail extends StatelessWidget {
  const MasterDetail({
    super.key,
    required this.master,
    required this.detail,
    this.emptyDetailText,
  });

  final Widget master;
  final Widget? detail;

  /// Prompt shown when [detail] is null; defaults to
  /// [S.chatSelectConversation] in the current locale.
  final String? emptyDetailText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(width: kMasterPaneWidth, child: master),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child:
              detail ??
              Center(
                child: Text(
                  emptyDetailText ?? context.s.chatSelectConversation,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}

/// Shows [message] in a snack bar if the [context] is still mounted.
void showSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Standard yes/no confirmation. Returns true when [confirmLabel] was tapped.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.s.actionCancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Locale-aware short timestamp for lists and bubbles: the time of day for
/// today, month + day for the current year, a short date otherwise. All
/// three come from [MaterialLocalizations], so `zh` renders `9月30日` and
/// `en` `Sep 30` without any format string in this file.
String formatMessageTime(BuildContext context, DateTime time, {DateTime? now}) {
  final MaterialLocalizations loc = MaterialLocalizations.of(context);
  final DateTime local = time.toLocal();
  final DateTime today = (now ?? DateTime.now()).toLocal();
  if (local.year == today.year &&
      local.month == today.month &&
      local.day == today.day) {
    return loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  if (local.year == today.year) return loc.formatShortMonthDay(local);
  return loc.formatShortDate(local);
}
