import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_entry.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

/// An [IdentityService] whose data directory never opens: pending while
/// [loading], else failing (no identity yet, or storage unavailable).
final class UnavailableIdentityService implements IdentityService {
  UnavailableIdentityService({required this.loading});

  final bool loading;
  int attempts = 0;

  @override
  Future<String> dataDirectory() {
    attempts++;
    return loading
        ? Completer<String>().future
        : Future<String>.error(StateError('no identity'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

/// The training settings route over [identity] with no shared host: the
/// placeholder a learning surface shows while its data cannot be opened.
Widget unavailableTrainingSettings(UnavailableIdentityService identity) =>
    Provider<IdentityService>.value(
      value: identity,
      child: const TrainingSettingsEntry(),
    );
