import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../di/app_settings.dart';
import '../i18n/key_value_store.dart';
import '../i18n/l10n_extension.dart';
import '../i18n/locale_controller.dart';
import '../ui/appearance/ui_style.dart';
import '../ui/chat/chat_layout.dart';
import '../ui/legal/legal_pages.dart';
import '../ui/theme.dart';
import 'initial_root_route.dart';
import 'startup_screens.dart';

bool requiresPrivacyConsent({
  bool releaseMode = kReleaseMode,
  TargetPlatform? platform,
}) =>
    releaseMode &&
    (platform ?? defaultTargetPlatform) == TargetPlatform.android;

/// Opens the local settings and obtains consent before starting the backend.
/// This gate is independent of the community terms required for chat.
class AndroidPrivacyStartup extends StatefulWidget {
  const AndroidPrivacyStartup({
    super.key,
    required this.openStore,
    required this.ready,
  });

  final Future<KeyValueStore> Function() openStore;
  final Widget Function(KeyValueStore store) ready;

  @override
  State<AndroidPrivacyStartup> createState() => _AndroidPrivacyStartupState();
}

class _AndroidPrivacyStartupState extends State<AndroidPrivacyStartup> {
  static const _consentKey = 'privacy.consent';
  // Bump when the app's privacy disclosures change materially.
  static const _consentVersion = '2';

  KeyValueStore? _store;
  Locale? _locale;
  AppSettings? _appearance;
  _PrivacyStartupPhase _phase = _PrivacyStartupPhase.opening;
  Widget? _ready;

  @override
  void initState() {
    super.initState();
    _openStore().ignore();
  }

  Future<void> _openStore() async {
    final KeyValueStore store;
    try {
      store = await widget.openStore();
    } on Object {
      if (mounted) setState(() => _phase = _PrivacyStartupPhase.failed);
      return;
    }
    if (!mounted) return;
    setState(() {
      _store = store;
      _locale = LocaleController.parseLocaleName(
        store.getString(LocaleController.storageKey),
      );
      _appearance = AppSettings(backendLabel: '', store: store);
      if (store.getString(_consentKey) == _consentVersion) {
        _ready = widget.ready(store);
      } else {
        _phase = _PrivacyStartupPhase.consent;
      }
    });
  }

  void _retry() {
    if (_phase != _PrivacyStartupPhase.failed) return;
    setState(() => _phase = _PrivacyStartupPhase.opening);
    _openStore().ignore();
  }

  Future<void> _accept() async {
    final store = _store!;
    await store.setString(_consentKey, _consentVersion);
    if (mounted) setState(() => _ready = widget.ready(store));
  }

  @override
  void dispose() {
    _appearance?.dispose();
    super.dispose();
  }

  Widget _gatePage(BuildContext context) {
    final s = context.s;
    return switch (context.watch<_PrivacyStartupPhase>()) {
      _PrivacyStartupPhase.opening => StartupSplash(
        message: s.accountStartupOpening,
      ),
      _PrivacyStartupPhase.failed => StartupErrorPage(
        title: s.privacyConsentTitle,
        message: s.privacyConsentSaveFailed,
        error: null,
        onRetry: _retry,
      ),
      _PrivacyStartupPhase.consent => _PrivacyConsentPage(onAccept: _accept),
    };
  }

  @override
  Widget build(BuildContext context) =>
      _ready ??
      MaterialApp(
        key: const ValueKey('android-privacy-startup'),
        onGenerateTitle: (context) => context.s.appName,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: _locale,
        localeListResolutionCallback: LocaleController.resolve,
        debugShowCheckedModeBanner: false,
        theme: DitmeshTheme.light(style: _appearance?.style ?? kDefaultUiStyle),
        darkTheme: DitmeshTheme.dark(
          style: _appearance?.style ?? kDefaultUiStyle,
        ),
        themeMode: _appearance?.themeMode,
        builder: (context, child) =>
            Provider<_PrivacyStartupPhase>.value(value: _phase, child: child),
        // Android can supply an initial route via an intent. Only this route is
        // available before consent, even when the intent names a protected page.
        onGenerateInitialRoutes: (_) => initialRootRoute(_gatePage),
        routes: {Navigator.defaultRouteName: _gatePage},
      );
}

enum _PrivacyStartupPhase { opening, failed, consent }

class _PrivacyConsentPage extends StatefulWidget {
  const _PrivacyConsentPage({required this.onAccept});

  final Future<void> Function() onAccept;

  @override
  State<_PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<_PrivacyConsentPage> {
  bool _saving = false;

  Future<void> _accept() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onAccept();
    } on Object {
      if (mounted) showSnack(context, context.s.privacyConsentSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.privacyConsentTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.privacyConsentSummary,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _open(const PrivacyPolicyPage()),
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: Text(s.aboutPrivacyPolicy),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _open(const TermsOfUsePage()),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(s.aboutTermsOfUse),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _accept,
                      child: Text(
                        _saving
                            ? s.privacyConsentSaving
                            : s.privacyConsentAccept,
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : SystemNavigator.pop,
                      child: Text(s.privacyConsentDecline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
