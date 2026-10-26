import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Two existing shell commands exposed to UIKit's iPad menu. No key commands
/// are registered natively: Flutter remains the sole owner of Cmd+K/N.
class IosMenuCommands {
  IosMenuCommands({
    required this.canInvoke,
    required this.onChanged,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(channelName) {
    _active = this;
    _channel.setMethodCallHandler(_handle);
  }

  static const channelName = 'icu.agentx.ditmesh/menu_commands';
  static IosMenuCommands? _active;
  static int _nextOwner = 0;
  final MethodChannel _channel;
  final bool Function() canInvoke;
  final VoidCallback onChanged;
  Object? _owner;
  String _ownerToken = '';
  VoidCallback? _search;
  VoidCallback? _contacts;
  Map<String, Object>? _last;
  bool _disposed = false;

  bool get enabled => !_disposed && _owner != null && canInvoke();

  void bind(
    Object owner, {
    required VoidCallback search,
    required VoidCallback contacts,
  }) {
    _owner = owner;
    _ownerToken = '${++_nextOwner}';
    _search = search;
    _contacts = contacts;
    onChanged();
  }

  void unbind(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _ownerToken = '';
    _search = null;
    _contacts = null;
    onChanged();
  }

  Future<Object?> _handle(MethodCall call) async {
    if (!identical(_active, this) || call.method != 'invoke' || !enabled) {
      return false;
    }
    final arguments = call.arguments;
    if (arguments is! Map || arguments['owner'] != _ownerToken) return false;
    switch (arguments['command']) {
      case 'search':
        _search!();
      case 'contacts':
        _contacts!();
      default:
        return false;
    }
    return true;
  }

  Future<void> publish({
    required String title,
    required String search,
    required String contacts,
  }) async {
    if (_disposed || !identical(_active, this)) return;
    final state = <String, Object>{
      'title': title,
      'search': search,
      'contacts': contacts,
      'enabled': enabled,
      'owner': _ownerToken,
    };
    if (mapEquals(_last, state)) return;
    _last = state;
    await _send(state);
  }

  Future<void> _send(Map<String, Object> state) async {
    try {
      await _channel.invokeMethod<Object?>('update', state);
    } on MissingPluginException {
      // Older iOS hosts and tests can omit this optional menu integration.
    } on PlatformException {
      // A menu failure never breaks the existing in-app command paths.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _owner = null;
    _ownerToken = '';
    _search = null;
    _contacts = null;
    if (!identical(_active, this)) return;
    _active = null;
    _channel.setMethodCallHandler(null);
    if (_last case final last?) await _send({...last, 'enabled': false});
  }
}
