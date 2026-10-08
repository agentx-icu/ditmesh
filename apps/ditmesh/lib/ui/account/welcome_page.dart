import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'account_widgets.dart';
import 'create_identity_page.dart';
import 'restore_backup_page.dart';

/// First screen on a fresh install: what a Tox identity is, why it must be
/// backed up, and the two ways forward (create / restore).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      body: AccountPageBody(
        children: [
          const SizedBox(height: 32),
          Icon(Icons.radio, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            s.appName,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(s.accountWelcomeTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(s.accountWelcomeIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          BulletLine(
            icon: Icons.cloud_off_outlined,
            text: s.accountWelcomePointNoServer,
          ),
          BulletLine(
            icon: Icons.forum_outlined,
            text: s.accountWelcomePointTraining,
          ),
          BulletLine(
            icon: Icons.warning_amber_outlined,
            text: s.accountWelcomePointBackup,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreateIdentityPage(),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(s.accountCreateIdentity),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RestoreBackupPage(),
              ),
            ),
            icon: const Icon(Icons.restore),
            label: Text(s.accountRestoreFromBackup),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
