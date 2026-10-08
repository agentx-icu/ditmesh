import 'package:flutter/foundation.dart';

/// Why the microphone could not be used, decided from reliable signals at
/// the source rather than from the platform's (English, unlocalised) error
/// text.
enum ListenFailureKind {
  /// `hasPermission()` answered false.
  permissionDenied,

  /// Starting capture threw and the platform's device list came back empty.
  noInputDevice,

  /// The permission query or starting capture threw for any other reason,
  /// including when the device list is unavailable on this platform.
  startFailed,

  /// The PCM stream reported an error after capture had started.
  streamFailed,
}

/// A typed Listen failure. [detail] is the platform's own error text, kept
/// for diagnostics only; the UI renders a localised message chosen by
/// [kind] and never shows [detail].
@immutable
final class ListenFailure {
  const ListenFailure(this.kind, {this.detail});

  final ListenFailureKind kind;
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is ListenFailure && other.kind == kind && other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, detail);

  @override
  String toString() => detail == null
      ? 'ListenFailure(${kind.name})'
      : 'ListenFailure(${kind.name}: $detail)';
}
