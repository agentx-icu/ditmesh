import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../di/app_settings.dart';
import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../i18n/language_settings_tile.dart';
import '../../notifications/notification_settings_section.dart';
import '../../startup/startup_controller.dart';
import '../account/account_routes.dart';
import '../account/account_widgets.dart';
import '../account/backup_actions.dart';
import '../account/change_password_page.dart';
import '../account/delete_identity_dialog.dart';
import '../account/edit_profile_page.dart';
import '../account/identity_card.dart';
import '../appearance/appearance_page.dart';
import '../appearance/style_labels.dart';
import '../common/app_bar_title.dart';
import '../diagnostics/connection_diagnostics_page.dart';
import '../keying/key_setup_page.dart';
import '../moderation/blocked_people_page.dart';
import '../moderation/site_links.dart';
import '../network/bootstrap_page.dart';

/// Profile, account, progress and settings.
class MePage extends StatelessWidget {
  const MePage({super.key});

  /// Destination label, resolved in the current locale.
  static String title(S s) => s.navMe;

  /// One-line subtitle, resolved in the current locale.
  static String description(S s) => s.navMeDescription;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final service = context.read<IdentityService>();
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(title(s))),
      body: StreamBuilder<Identity?>(
        stream: service.identityChanges,
        initialData: service.current,
        builder: (context, snapshot) {
          final identity = snapshot.data;
          if (identity == null) {
            return Center(child: Text(s.accountMeNoIdentity));
          }
          return _MeBody(identity: identity);
        },
      ),
    );
  }
}

class _MeBody extends StatelessWidget {
  const _MeBody({required this.identity});

  final Identity identity;

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _delete(BuildContext context) async {
    final s = context.s;
    final controller = context.read<StartupController>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!await confirmDeleteIdentity(context)) return;
    try {
      await controller.deleteIdentity();
    } on Object catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(describeChatError(s, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final backend = context.watch<AppSettings>().backendLabel;
    return AccountPageBody(
      maxWidth: 640,
      children: [
        IdentityCard(identity: identity),
        _SectionHeader(s.accountSectionAccount),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(s.accountEditProfile),
          subtitle: Text(s.accountEditProfileBody),
          onTap: () => _push(context, EditProfilePage(identity: identity)),
        ),
        ListTile(
          leading: const Icon(Icons.password),
          title: Text(
            identity.hasPassword
                ? s.accountChangePassword
                : s.accountSetPassword,
          ),
          onTap: () => _push(
            context,
            ChangePasswordPage(hasPassword: identity.hasPassword),
          ),
        ),
        // The tile's own context anchors the iPad share popover.
        Builder(
          builder: (tile) => ListTile(
            leading: const Icon(Icons.save_alt),
            title: Text(s.accountExportBackup),
            subtitle: Text(
              context.read<IdentityService>() is EncryptedBackupService
                  ? s.backupXMeSubtitle
                  : s.accountExportBackupSubtitle,
            ),
            onTap: () => exportBackupWithFeedback(context, anchor: tile),
          ),
        ),
        ListTile(
          key: const ValueKey('me-blocked-people'),
          leading: const Icon(Icons.block),
          title: Text(s.moderationBlockedTitle),
          subtitle: Text(s.moderationBlockedSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => BlockedPeoplePage.open(context),
        ),
        ListTile(
          key: const ValueKey('me-connection-diagnostics'),
          leading: const Icon(Icons.network_check),
          title: Text(s.diagTitle),
          subtitle: Text(s.diagOpenSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ConnectionDiagnosticsPage.open(context),
        ),
        ListTile(
          key: const ValueKey('me-network-bootstrap'),
          leading: const Icon(Icons.hub_outlined),
          title: Text(s.bootstrapTitle),
          subtitle: Text(s.bootstrapDescription),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => BootstrapPage.open(context),
        ),
        _SectionHeader(s.accountSectionTraining),
        ListTile(
          leading: const Icon(Icons.tune),
          title: Text(s.accountTrainingDefaults),
          subtitle: Text(s.accountTrainingDefaultsSubtitle),
          onTap: () => Navigator.of(context).pushNamed(kTrainingSettingsRoute),
        ),
        ListTile(
          key: const ValueKey('me-keys'),
          leading: const Icon(Icons.keyboard_outlined),
          title: Text(s.keysTitle),
          subtitle: Text(s.keysMeSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => KeySetupPage.open(context),
        ),
        const LanguageSettingsTile(),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(s.appearanceTitle),
          subtitle: Text(styleLabel(s, context.watch<AppSettings>().style)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => AppearancePage.open(context),
        ),
        NotificationSettingsSection(
          header: _SectionHeader(s.accountSectionNotifications),
        ),
        _SectionHeader(s.accountSectionAbout),
        const SiteLinksSection(),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(s.accountAboutLicence),
          subtitle: Text(s.accountAboutLicenceValue),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(s.accountAboutSource),
          subtitle: const Text(kAboutSourceUrl),
          trailing: const Icon(Icons.copy, size: 18),
          onTap: () => copyToClipboard(
            context,
            kAboutSourceUrl,
            confirmation: s.accountAboutSourceCopied,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.hub_outlined),
          title: Text(s.accountAboutBackend),
          subtitle: Text(backend),
        ),
        _SectionHeader(s.accountSectionDanger, color: theme.colorScheme.error),
        ListTile(
          leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
          title: Text(
            s.accountDeleteIdentity,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          subtitle: Text(s.accountDeleteIdentitySubtitle),
          onTap: () => _delete(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4, left: 16),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}
