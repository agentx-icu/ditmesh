import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../di/app_features.dart';
import '../../i18n/l10n_extension.dart';
import '../../i18n/language_settings_tile.dart';
import '../../startup/startup_controller.dart';
import '../appearance/appearance_page.dart';
import '../common/app_bar_title.dart';
import '../moderation/site_links.dart';
import '../pages/offline_me_page.dart';
import '../responsive.dart';

StartupController? _startup(BuildContext context, {bool listen = true}) {
  try {
    return listen
        ? context.watch<StartupController>()
        : context.read<StartupController>();
  } on ProviderNotFoundException {
    return null;
  }
}

/// Whether the app runs on the guest learning profile.
bool isGuestMode(BuildContext context) =>
    _startup(context)?.phase == StartupPhase.guest;

/// "Try learning first" on the welcome and unlock pages (spec §8.1).
class TryLearningFirstButton extends StatelessWidget {
  const TryLearningFirstButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = _startup(context, listen: false);
    if (controller == null || !controller.guestAvailable) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      key: const ValueKey('try-learning-first'),
      onPressed: () => unawaited(controller.enterGuest()),
      icon: const Icon(Icons.school_outlined),
      label: Text(context.s.guestTryLearning),
    );
  }
}

/// The shell in guest mode: a slim banner over the normal destinations.
/// The offline build has no identity to offer, so no banner.
class GuestShell extends StatelessWidget {
  const GuestShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.read<AppFeatures>().chat) return child;
    final s = context.s;
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Material(
          color: theme.colorScheme.secondaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.person_off_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.guestBanner,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => unawaited(
                      context.read<StartupController>().leaveGuest(),
                    ),
                    child: Text(s.guestGetIdentity),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Chat, Groups and Me need a real identity; in guest mode they explain
/// that and offer create / restore / unlock instead of a fake chat.
class IdentityRequiredGate extends StatelessWidget {
  const IdentityRequiredGate({
    super.key,
    required this.child,
    this.isMe = false,
  });

  final Widget child;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (!isGuestMode(context)) return child;
    // The offline build's only Me: settings of the learning profile.
    if (!context.read<AppFeatures>().chat && isMe) {
      return const OfflineMePage();
    }
    final s = context.s;
    final theme = Theme.of(context);
    final controller = context.read<StartupController>();
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(isMe ? s.navMe : s.guestIdentityTitle)),
      body: ReadableBody(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Icon(
              Icons.forum_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              s.guestIdentityBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('guest-get-identity'),
              onPressed: () => unawaited(controller.leaveGuest()),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(s.guestGetIdentity),
            ),
            if (isMe) ...<Widget>[
              const SizedBox(height: 24),
              const LanguageSettingsTile(),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(s.appearanceTitle),
                onTap: () => AppearancePage.open(context),
              ),
              const SiteLinksSection(),
              ListTile(
                key: const ValueKey('guest-clear'),
                leading: const Icon(Icons.delete_outline),
                title: Text(s.guestClearData),
                subtitle: Text(s.guestClearDataBody),
                onTap: () => unawaited(_clear(context, controller)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> _clear(
    BuildContext context,
    StartupController controller,
  ) async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(s.guestClearData),
        content: Text(s.guestClearDataBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.guestClearConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await controller.clearGuestData();
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(s.guestCleared)));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(s.guestClearFailed)));
      }
    }
  }
}

/// After create/restore/unlock: a failed guest migration (with retry) or
/// the choice between restored and guest progress. Nothing is merged.
class GuestDataBanner extends StatelessWidget {
  const GuestDataBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = _startup(context);
    if (controller == null ||
        (controller.migrationError == null && !controller.guestChoicePending)) {
      return child;
    }
    final s = context.s;
    final failed = controller.migrationError != null;
    return Column(
      children: <Widget>[
        MaterialBanner(
          content: Text(failed ? s.guestMigrationFailed : s.guestChoiceBody),
          leading: Icon(failed ? Icons.sync_problem : Icons.merge_type),
          actions: failed
              ? <Widget>[
                  TextButton(
                    onPressed: () => unawaited(controller.retryMigration()),
                    child: Text(s.actionRetry),
                  ),
                ]
              : <Widget>[
                  TextButton(
                    onPressed: () =>
                        unawaited(controller.keepRestoredProgress()),
                    child: Text(s.guestChoiceKeep),
                  ),
                  TextButton(
                    key: const ValueKey('guest-use-progress'),
                    onPressed: () => unawaited(controller.useGuestProgress()),
                    child: Text(s.guestChoiceUseGuest),
                  ),
                ],
        ),
        Expanded(child: child),
      ],
    );
  }
}
