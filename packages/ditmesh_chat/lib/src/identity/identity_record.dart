import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../util/atomic_file.dart';

/// `identity.json`: the identity's durable profile fields.
///
/// Tox savedata also stores the name and status, but reading them requires an
/// initialised Tox instance, and the startup gate must know the Tox ID (to
/// scope preferences and the password verifier) before it decides whether to
/// prompt for a password. So the fields are mirrored here, written on every
/// change, and re-applied to Tox on every connect.
class IdentityRecord {
  const IdentityRecord({
    required this.toxId,
    required this.displayName,
    this.statusMessage = '',
    this.hasPassword = false,
  });

  final String toxId;
  final String displayName;
  final String statusMessage;

  /// Mirror of the password verifier's state, so `inspect()` can answer
  /// `locked` even when the secure store is temporarily unreadable.
  final bool hasPassword;

  Identity toIdentity() => Identity(
    toxId: toxId,
    displayName: displayName,
    statusMessage: statusMessage,
    hasPassword: hasPassword,
  );

  IdentityRecord copyWith({
    String? toxId,
    String? displayName,
    String? statusMessage,
    bool? hasPassword,
  }) => IdentityRecord(
    toxId: toxId ?? this.toxId,
    displayName: displayName ?? this.displayName,
    statusMessage: statusMessage ?? this.statusMessage,
    hasPassword: hasPassword ?? this.hasPassword,
  );

  Map<String, Object?> toJson() => {
    'version': 1,
    'toxId': toxId,
    'displayName': displayName,
    'statusMessage': statusMessage,
    'hasPassword': hasPassword,
  };

  static IdentityRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final toxId = json['toxId'];
    final name = json['displayName'];
    if (toxId is! String || toxId.isEmpty || name is! String) return null;
    final status = json['statusMessage'];
    final protected = json['hasPassword'];
    if (status != null && status is! String ||
        protected != null && protected is! bool) {
      return null;
    }
    return IdentityRecord(
      toxId: toxId.toUpperCase(),
      displayName: name,
      statusMessage: status as String? ?? '',
      hasPassword: protected as bool? ?? false,
    );
  }

  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  static IdentityRecord? decode(Uint8List bytes) {
    try {
      return fromJson(jsonDecode(utf8.decode(bytes)));
    } on FormatException {
      return null;
    }
  }

  static Future<IdentityRecord?> read(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return decode(await file.readAsBytes());
  }

  /// Flushed staging write followed by an atomic replacement.
  Future<void> write(String path) => writeBytesAtomic(File(path), encode());
}
