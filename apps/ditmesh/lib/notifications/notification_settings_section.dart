import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/l10n_extension.dart';
import 'local_notifications_api.dart';
import 'notification_center.dart';
import 'notification_prefs.dart';

/// The Me page's notification settings: the master switch, whether banners
/// (and the lock screen) show the message itself, and — where the OS asks
/// first — a way to grant the permission from the foreground. When the user
/// has turned the message channel off in the Android settings the switch
/// keeps showing their in-app preference and a status line says why no
/// banner arrives.
///
/// "Message content" drives both [NotificationPrefs.showText] and
/// [NotificationPrefs.showPattern]: a Morse pattern reveals the text as well,
/// so hiding one but not the other would not hide anything.
class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({
    super.key,
    required this.header,
    this.showSystemStatus = true,
  });

  /// The section header, styled by the page.
  final Widget header;
  final bool showSystemStatus;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final NotificationPrefs prefs = context.watch<NotificationPrefs>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(s.accountNotificationsEnable),
          subtitle: Text(s.accountNotificationsEnableSubtitle),
          value: prefs.enabled,
          onChanged: (on) => prefs.enabled = on,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.visibility_outlined),
          title: Text(s.accountNotificationsContent),
          subtitle: Text(s.accountNotificationsContentSubtitle),
          value: prefs.showText || prefs.showPattern,
          onChanged: prefs.enabled
              ? (on) => prefs
                  ..showText = on
                  ..showPattern = on
              : null,
        ),
        if (showSystemStatus) const NotificationSystemStatus(),
      ],
    );
  }
}

/// The separate OS permission and channel status can also appear beside the
/// user's saved notification preferences.
class NotificationSystemStatus extends StatelessWidget {
  const NotificationSystemStatus({super.key, this.showSummary = false});

  final bool showSummary;

  Future<void> _allow(BuildContext context, NotificationCenter center) async {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final String denied = context.s.accountNotificationsDenied;
    if (!await center.ensurePermission()) {
      messenger?.showSnackBar(SnackBar(content: Text(denied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final center = context.read<NotificationCenter?>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSummary)
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(s.accountNotificationsSystemManaged),
          ),
        if (center != null)
          ValueListenableBuilder<Set<NotificationChannelKind>>(
            valueListenable: center.blockedChannels,
            builder: (context, blocked, _) {
              if (blocked.contains(NotificationChannelKind.messages)) {
                return ListTile(
                  leading: const Icon(Icons.notifications_off_outlined),
                  title: Text(s.accountNotificationsBlocked),
                  subtitle: Text(s.accountNotificationsBlockedSubtitle),
                );
              }
              if (!center.needsPermission) return const SizedBox.shrink();
              return ValueListenableBuilder<bool>(
                valueListenable: center.permissionGranted,
                builder: (context, allowed, _) => allowed
                    ? ListTile(
                        leading: const Icon(
                          Icons.notifications_active_outlined,
                        ),
                        title: Text(s.accountNotificationsPermitted),
                      )
                    : ListTile(
                        leading: const Icon(Icons.notification_add_outlined),
                        title: Text(s.accountNotificationsAllow),
                        subtitle: Text(s.accountNotificationsAllowSubtitle),
                        onTap: () => unawaited(_allow(context, center)),
                      ),
              );
            },
          ),
      ],
    );
  }
}
