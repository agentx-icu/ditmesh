import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../desktop/ios_menu_commands.dart';
import '../../di/app_settings.dart';
import '../../i18n/l10n_extension.dart';
import '../../startup/startup_controller.dart';

/// Keeps localized commands visible but disabled before the startup gate is
/// ready. AppShell binds the existing actions only while it owns the session.
class IosMenuHost extends StatefulWidget {
  const IosMenuHost({super.key, required this.child});

  final Widget child;

  @override
  State<IosMenuHost> createState() => _IosMenuHostState();
}

class _IosMenuHostState extends State<IosMenuHost> with WidgetsBindingObserver {
  IosMenuCommands? _commands;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _commands = IosMenuCommands(canInvoke: _canInvoke, onChanged: _schedule);
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_schedule);
  }

  bool _canInvoke() =>
      mounted &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
      context.read<StartupController>().phase == StartupPhase.ready &&
      context.read<AppSettings>().termsAccepted &&
      context.read<IdentityService>().current != null &&
      (ModalRoute.of(context)?.isCurrent ?? false) &&
      FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<EditableText>() ==
          null;

  void _schedule() {
    if (!mounted || _scheduled || _commands == null) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final s = context.s;
      unawaited(
        _commands!.publish(
          title: s.navChat,
          search: s.chatSearchConversations,
          contacts: s.chatContacts,
        ),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _schedule();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_schedule);
    unawaited(_commands?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to route and locale changes so menus refresh while covered.
    ModalRoute.of(context);
    context.s;
    if (_commands != null) {
      context.watch<StartupController>();
      context.watch<AppSettings>();
    }
    _schedule();
    return Provider<IosMenuCommands?>.value(
      value: _commands,
      child: widget.child,
    );
  }
}
