import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../di/app_settings.dart';
import '../../i18n/l10n_extension.dart';
import '../account/account_routes.dart';
import '../chat/chat_layout.dart';
import '../common/app_bar_title.dart';
import 'site_links.dart';

/// Community guidelines the user accepts before using an identity (App
/// Review 1.2: zero tolerance for objectionable content and abusive users).
/// Shown by the startup gate instead of the shell while the current
/// [kTermsVersion] is not accepted on this device, so neither a tab nor a
/// notification tap nor a pushed route can reach chat before it. Guest
/// learning never sees it (there is no chat without an identity).
class TermsGatePage extends StatefulWidget {
  const TermsGatePage({super.key});

  @override
  State<TermsGatePage> createState() => _TermsGatePageState();
}

class _TermsGatePageState extends State<TermsGatePage> {
  bool _saving = false;

  Future<void> _agree() async {
    if (_saving) return;
    setState(() => _saving = true);
    final S s = context.s;
    try {
      await context.read<AppSettings>().acceptTerms();
    } on Object {
      if (mounted) showSnack(context, s.termsGateSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    final ThemeData theme = Theme.of(context);
    Widget rule(IconData icon, String text) => ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(text),
      contentPadding: EdgeInsets.zero,
    );
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.termsGateTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(s.termsGateIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                rule(Icons.gpp_bad_outlined, s.termsGateRuleZero),
                rule(Icons.how_to_reg_outlined, s.termsGateRuleContacts),
                rule(Icons.block, s.termsGateRuleBlock),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('terms-read-full'),
                    onPressed: () =>
                        unawaited(openSiteLink(context, kTermsUrl)),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(s.termsGateReadFull),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('terms-privacy'),
                    onPressed: () =>
                        unawaited(openSiteLink(context, kPrivacyPolicyUrl)),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(s.aboutPrivacyPolicy),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('terms-agree'),
                  onPressed: _saving ? null : () => unawaited(_agree()),
                  child: Text(s.termsGateAgree),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
