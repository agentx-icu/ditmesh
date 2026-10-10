// Remote-controlled probe behind integration_test/device_matrix_test.dart.
// Read that file's header for the log and command formats.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ViewPadding;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/lifecycle/app_lifecycle_coordinator.dart';
import 'package:ditmesh/notifications/notification_center.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'scene_walk.dart';
import 'shot_harness.dart';

int _now() => DateTime.now().millisecondsSinceEpoch;

void _log(String line) => debugPrint('DMX_$line');

/// Pumps until [finder] matches or [timeout] passes.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  await settle(tester);
}

final class DeviceProbe with WidgetsBindingObserver {
  DeviceProbe(this.tester);

  final WidgetTester tester;
  final List<StreamSubscription<Object?>> _subs = [];
  late final IdentityService _identity;
  late final ChatService _chat;
  late final AppLifecycleCoordinator _lifecycle;
  NotificationCenter? _notifications;
  late final File _cmd;
  int _lastSeq = 0;
  int _errors = 0;
  String _lastState = '';
  FlutterExceptionHandler? _previousOnError;
  bool _quit = false;

  BuildContext get _ctx => tester.element(find.byType(AppShell));
  S get _s => S.of(tester.element(find.byType(Scaffold).first));

  Future<void> start() async {
    final ctx = _ctx;
    _identity = ctx.read<IdentityService>();
    _chat = ctx.read<ChatService>();
    _lifecycle = ctx.read<AppLifecycleCoordinator>();
    _notifications = ctx.read<NotificationCenter?>();
    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'dmx'),
    )..createSync(recursive: true);
    _cmd = File(p.join(dir.path, 'cmd'));
    // Commands written before this launch belong to an earlier run.
    if (_cmd.existsSync()) _lastSeq = _maxSeq(_cmd.readAsLinesSync());
    _log('CMD_DIR ${dir.path} lastSeq=$_lastSeq');
    _log('TOXID ${_identity.current?.toxId}');
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _errors++;
      _log('FLUTTER_ERROR ${details.exceptionAsString().split('\n').first}');
      _previousOnError?.call(details);
    };
    WidgetsBinding.instance.addObserver(this);
    _subs
      ..add(_lifecycle.hints.listen((h) => _log('HINT ${h.name} ${_now()}')))
      ..add(
        _identity.connectionChanges.listen(
          (c) => _log('CONN ${c.name} ${_now()}'),
        ),
      )
      ..add(_chat.messageEvents.listen(_onMessage))
      ..add(_chat.friendRequestChanges.listen(_acceptAll));
    _acceptAll(_chat.friendRequests);
    _printState(force: true);
  }

  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs) {
      await s.cancel();
    }
    FlutterError.onError = _previousOnError;
    await SystemChrome.setPreferredOrientations(const []);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _log('LIFE ${state.name} ${_now()}');

  void _onMessage(ChatMessage m) => _log(
    'MSG ${_short(m.conversationId)} ${m.status.name} '
    'mine=${m.isMine} id=${m.id} "${m.text}" ${_now()}',
  );

  void _acceptAll(List<FriendRequest> requests) {
    for (final r in requests) {
      _log('ACCEPT ${_short(r.publicKey)}');
      unawaited(
        _chat.acceptFriendRequest(r.publicKey).catchError((Object e) {
          _log('ACCEPT_FAILED $e');
        }),
      );
    }
  }

  /// Heartbeat, state and command loop. Timers keep running while the app
  /// is in the background (until the OS freezes the process), frames do
  /// not, so nothing here pumps unless a command needs the UI.
  Future<void> run(Duration limit) async {
    final end = DateTime.now().add(limit);
    while (!_quit && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      _log('HB ${_now()}');
      // The test binding paints only when the test pumps; keep the screen
      // current while it is visible (a pump would wait for a frame the
      // engine does not produce in the background).
      final life = WidgetsBinding.instance.lifecycleState;
      if (life == AppLifecycleState.resumed ||
          life == AppLifecycleState.inactive) {
        await tester.pump();
      }
      _printState();
      await _poll();
    }
  }

  Future<void> _poll() async {
    if (!_cmd.existsSync()) return;
    for (final line in _cmd.readAsLinesSync()) {
      final parts = line.trim().split(RegExp(r'\s+'));
      final seq = int.tryParse(parts.first);
      if (seq == null || seq <= _lastSeq) continue;
      _lastSeq = seq;
      try {
        final detail = await execute(parts[1], parts.skip(2).toList());
        _log('DONE $seq ok $detail');
      } catch (e) {
        _log('DONE $seq error ${'$e'.split('\n').first}');
      }
      _printState(force: true);
    }
  }

  /// One command. UI verbs need the app in the foreground.
  Future<String> execute(String verb, List<String> args) async {
    switch (verb) {
      case 'status':
        return '';
      case 'addfriend':
        await _chat.addFriend(args.single);
        return 'requested';
      case 'open':
        return _open(args.single);
      case 'close':
        await popIfCan(tester);
        return '';
      case 'draft':
        _composer().controller!.value = TextEditingValue(
          text: args.join(' '),
          selection: TextSelection.collapsed(offset: args.join(' ').length),
        );
        await settle(tester);
        return _composer().controller!.text;
      case 'send':
        await tapTooltip(tester, _s.chatSend);
        return '';
      case 'history':
        final rows = await _chat.loadHistory('c2c_${args.single}');
        return rows
            .map((m) => '${m.status.name}:${m.isMine}:"${m.text}"')
            .join(' | ');
      case 'orient':
        await SystemChrome.setPreferredOrientations(switch (args.single) {
          'landscape' => const [DeviceOrientation.landscapeLeft],
          'portrait' => const [DeviceOrientation.portraitUp],
          _ => const <DeviceOrientation>[],
        });
        await tester.pump(const Duration(seconds: 2));
        await settle(tester);
        return '';
      case 'tab':
        await selectTab(tester, ShellTab.values.byName(args.single));
        return '';
      case 'findtext':
        return _findText(args.join(' '));
      case 'pump':
        await settle(tester, extra: const Duration(seconds: 1));
        return '';
      case 'quit':
        _quit = true;
        return '';
    }
    throw ArgumentError('unknown verb $verb');
  }

  TextField _composer() => tester.widget<TextField>(
    find
        .descendant(
          of: find.byType(ConversationScreen),
          matching: find.byType(TextField),
        )
        .last,
  );

  Future<String> _open(String publicKey) async {
    if (find.byType(ConversationScreen).evaluate().isNotEmpty) {
      return 'already open';
    }
    await selectTab(tester, ShellTab.chat);
    await tapTooltip(tester, _s.chatContacts);
    await tapHittable(
      tester,
      find.byKey(ValueKey<String>('friend_$publicKey')),
      'friend row',
    );
    await waitFor(tester, find.byType(ConversationScreen));
    ScaffoldMessenger.of(
      tester.element(find.byType(ConversationScreen)),
    ).clearSnackBars();
    await settle(tester);
    return 'opened';
  }

  /// `accountNotificationsBlocked` and the like: the ARB key is resolved in
  /// the current language, then scrolled to on the visible page.
  Future<String> _findText(String key) async {
    final text = switch (key) {
      'accountNotificationsBlocked' => _s.accountNotificationsBlocked,
      _ => key,
    };
    final finder = find.text(text);
    final scrollable = find.byType(Scrollable).hitTestable();
    if (finder.evaluate().isEmpty && scrollable.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: scrollable.first,
          maxScrolls: 30,
        );
      } on StateError {
        // Not found after maxScrolls: reported below.
      }
    }
    return 'found=${finder.evaluate().length} "$text"';
  }

  void _printState({bool force = false}) {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final dpr = view.devicePixelRatio;
    final outbox = _chat is OutboxInspector
        ? (_chat as OutboxInspector).pendingOutbox()?.count
        : null;
    final state = <String, Object?>{
      'life': WidgetsBinding.instance.lifecycleState?.name,
      'fg': _lifecycle.isForeground.value,
      'mbd': _lifecycle.mayBeDisconnected.value,
      'conn': _identity.connectionStatus.name,
      'friends': [
        for (final f in _chat.friends) '${_short(f.publicKey)}:${f.online}',
      ],
      'outbox': outbox,
      'conv': find.byType(ConversationScreen).evaluate().length,
      'blocked': [
        for (final c in _notifications?.blockedChannels.value ?? const {})
          c.name,
      ],
      'size':
          '${(view.physicalSize.width / dpr).round()}x'
          '${(view.physicalSize.height / dpr).round()}',
      'pad': _insets(view.padding, dpr),
      'gesture': _insets(view.systemGestureInsets, dpr),
      'text': WidgetsBinding.instance.platformDispatcher.textScaleFactor,
      'errors': _errors,
    };
    final json = jsonEncode(state);
    if (!force && json == _lastState) return;
    _lastState = json;
    _log('STATE ${_now()} $json');
  }

  static String _insets(ViewPadding v, double dpr) =>
      '${(v.left / dpr).round()},${(v.top / dpr).round()},'
      '${(v.right / dpr).round()},${(v.bottom / dpr).round()}';

  static String _short(String id) => id.length > 12 ? id.substring(0, 12) : id;

  static int _maxSeq(List<String> lines) => lines
      .map((l) => int.tryParse(l.trim().split(RegExp(r'\s+')).first) ?? 0)
      .fold(0, (a, b) => a > b ? a : b);
}
