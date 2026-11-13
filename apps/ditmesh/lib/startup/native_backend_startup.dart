import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../di/app_settings.dart';
import '../di/backend_factory.dart';
import '../i18n/key_value_store.dart';
import '../i18n/locale_controller.dart';
import '../l10n/generated/s.dart';
import '../ui/theme.dart';
import 'initial_root_route.dart';
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

  void _retry() {
    final backend = widget.prepare();
    setState(() {
      _backend = backend;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<BackendFactory>(
    future: _backend,
    builder: (context, snapshot) {
      final backend = snapshot.data;
      if (backend != null) return widget.ready(backend);
      Widget buildHome(BuildContext context) =>
          _NativeBackendStatus(onRetry: _retry);
      return MaterialApp(
        key: const ValueKey('native-backend-startup'),
        onGenerateTitle: (context) => S.of(context).appName,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: _locale.locale,
        localeListResolutionCallback: LocaleController.resolve,
        debugShowCheckedModeBanner: false,
        theme: DitmeshTheme.light(style: _appearance.style),
        darkTheme: DitmeshTheme.dark(style: _appearance.style),
        themeMode: _appearance.themeMode,
        onGenerateInitialRoutes: (_) => initialRootRoute(buildHome),
        routes: {Navigator.defaultRouteName: buildHome},
        builder: (context, child) =>
            Provider<AsyncSnapshot<BackendFactory>>.value(
              value: snapshot,
              child: child,
            ),
      );
    },
  );
}

class _NativeBackendStatus extends StatelessWidget {
  const _NativeBackendStatus({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final snapshot = context.watch<AsyncSnapshot<BackendFactory>>();
    if (snapshot.connectionState != ConnectionState.done) {
      return StartupSplash(message: s.accountStartupOpening);
    }
    return StartupErrorPage(
      title: s.backendStartupFailedTitle,
      message: s.backendStartupFailedBody,
      error: snapshot.error,
      onRetry: onRetry,
    );
  }
}
