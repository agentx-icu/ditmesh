import 'package:flutter/material.dart';

import '../di/app_settings.dart';
import '../di/backend_factory.dart';
import '../i18n/key_value_store.dart';
import '../i18n/locale_controller.dart';
import '../l10n/generated/s.dart';
import '../ui/theme.dart';
import 'startup_screens.dart';

/// Starts the native transport before constructing any identity/chat service.
/// Preparation errors remain visible and retryable; no fake session is opened.
class NativeBackendStartup extends StatefulWidget {
  const NativeBackendStartup({
    super.key,
    required this.prepare,
    required this.ready,
    required this.store,
  });

  final Future<BackendFactory> Function() prepare;
  final Widget Function(BackendFactory backend) ready;
  final KeyValueStore store;

  @override
  State<NativeBackendStartup> createState() => _NativeBackendStartupState();
}

class _NativeBackendStartupState extends State<NativeBackendStartup> {
  late Future<BackendFactory> _backend = widget.prepare();
  late final LocaleController _locale = LocaleController(widget.store);
  late final AppSettings _appearance = AppSettings(
    backendLabel: '',
    store: widget.store,
  );

  @override
  void dispose() {
    _locale.dispose();
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<BackendFactory>(
    future: _backend,
    builder: (context, snapshot) {
      final backend = snapshot.data;
      if (backend != null) return widget.ready(backend);
      return MaterialApp(
        onGenerateTitle: (context) => S.of(context).appName,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: _locale.locale,
        localeListResolutionCallback: LocaleController.resolve,
        debugShowCheckedModeBanner: false,
        theme: DitmeshTheme.light(style: _appearance.style),
        darkTheme: DitmeshTheme.dark(style: _appearance.style),
        themeMode: _appearance.themeMode,
        home: Builder(
          builder: (context) {
            final s = S.of(context);
            if (snapshot.connectionState != ConnectionState.done) {
              return StartupSplash(message: s.accountStartupOpening);
            }
            return StartupErrorPage(
              title: s.backendStartupFailedTitle,
              message: s.backendStartupFailedBody,
              error: snapshot.error,
              onRetry: () {
                final backend = widget.prepare();
                setState(() {
                  _backend = backend;
                });
              },
            );
          },
        ),
      );
    },
  );
}
