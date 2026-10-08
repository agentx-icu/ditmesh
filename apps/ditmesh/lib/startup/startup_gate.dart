import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../di/app_settings.dart';
import '../i18n/l10n_extension.dart';
import '../ui/account/backup_wizard_page.dart';
import '../ui/account/connection_chip.dart';
import '../ui/account/guest_widgets.dart';
import '../ui/account/unlock_page.dart';
import '../ui/account/welcome_page.dart';
import '../ui/moderation/terms_gate_page.dart';
import 'startup_controller.dart';
import 'startup_screens.dart';

/// Wraps the whole shell: nothing behind it renders until an identity is
/// loaded — or the learner chose to learn as a guest first (functional spec
/// §8; Chat, Groups and Me then ask for an identity). Reads the
/// [StartupController] provided by `AppScope` and kicks it off once.
///
/// While [StartupPhase.ready], [child] is shown below a [ConnectionStrip]
/// that carries the connection chip whenever the node is not online — once
/// the community guidelines ([kTermsVersion]) are accepted on this device;
/// until then [TermsGatePage] stands in for the whole shell.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.child});

  final Widget child;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  @override
  void initState() {
    super.initState();
    // Notifies only after an await, so no markNeedsBuild during this build.
    context.read<StartupController>().ensureStarted().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final controller = context.watch<StartupController>();
    final phase = controller.phase;
    final bool termsAccepted = context.select<AppSettings, bool>(
      (settings) => settings.termsAccepted,
    );
    final Widget page = switch (phase) {
      StartupPhase.inspecting => StartupSplash(
        message: s.accountStartupInspecting,
      ),
      StartupPhase.opening => StartupSplash(message: s.accountStartupOpening),
      StartupPhase.onboarding => const WelcomePage(),
      StartupPhase.locked => const UnlockPage(),
      StartupPhase.backupRequired => const BackupWizardPage(mandatory: true),
      StartupPhase.failed => StartupErrorPage(
        error: controller.error,
        onRetry: () => controller.retry().ignore(),
      ),
      StartupPhase.ready when !termsAccepted => const TermsGatePage(),
      StartupPhase.ready => ConnectionStrip(
        child: GuestDataBanner(child: widget.child),
      ),
      // Learning on the guest profile: no identity, no connection.
      StartupPhase.guest => GuestShell(child: widget.child),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey((phase, phase != StartupPhase.ready || termsAccepted)),
        child: page,
      ),
    );
  }
}
