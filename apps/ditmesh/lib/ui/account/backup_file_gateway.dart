import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import '../../i18n/current_strings.dart';

typedef SavedBackup = ({bool completed, String? path});

typedef PickedBackup = ({Uint8List bytes, String? name});

/// Where backup bytes go and come from. Abstracted so widget tests never
/// touch the native pickers and so the platform split (save dialog on
/// desktop, share sheet on mobile) lives in exactly one place.
abstract interface class BackupFileGateway {
  /// Hands [bytes] to the user and reports completion and the actual path if
  /// the desktop picker returned one. Throws on I/O failure.
  ///
  /// [shareOrigin] is the global rect of the control that triggered the
  /// export. iPadOS presents the share sheet as a popover anchored to it;
  /// without one the popover floats in the middle of the screen, detached
  /// from the button. Ignored by the desktop save dialog.
  Future<SavedBackup> saveBackup(
    Uint8List bytes, {
    required String fileName,
    Rect? shareOrigin,
  });

  /// Lets the user pick a backup file; null when cancelled.
  Future<PickedBackup?> pickBackup();
}

/// Real implementation: `file_picker` save dialog on desktop, `share_plus`
/// share sheet on Android/iOS (there is no user-visible file system to save
/// into, and the share sheet reaches Files / Drive / AirDrop / mail).
final class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway();

  static const _mimeType = 'application/octet-stream';

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<SavedBackup> saveBackup(
    Uint8List bytes, {
    required String fileName,
    Rect? shareOrigin,
  }) async {
    if (_isMobile) {
      final handedOff = await _shareOnMobile(bytes, fileName, shareOrigin);
      return (completed: handedOff, path: null);
    }
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: _mimeType,
      // No BuildContext this deep: the native dialog reads the current
      // UI language through currentS().
      dialogTitle: currentS().accountBackupSaveDialogTitle,
    );
    final path = switch (uri?.scheme) {
      'file' => uri!.toFilePath(),
      '' => uri?.path,
      _ => null,
    };
    return (
      completed: uri != null,
      path: path != null && p.isAbsolute(path) ? path : null,
    );
  }

  Future<bool> _shareOnMobile(
    Uint8List bytes,
    String fileName,
    Rect? shareOrigin,
  ) async {
    // The share sheet needs a real file; the app's temp dir is private to us
    // and readable by the share extension.
    final dir = await Directory.systemTemp.createTemp('ditmesh_backup_');
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: _mimeType, name: fileName)],
          subject: currentS().accountBackupShareSubject,
          sharePositionOrigin: shareOrigin,
        ),
      );
      return result.status != ShareResultStatus.dismissed;
    } finally {
      // Best effort; a leftover temp file is harmless.
      await dir.delete(recursive: true).then<void>((_) {}, onError: (_) {});
    }
  }

  @override
  Future<PickedBackup?> pickBackup() async {
    final file = await FilePicker.pickFile(
      dialogTitle: currentS().accountBackupChooseDialogTitle,
    );
    if (file == null) return null;
    // A real backup is a profile plus training state, a few hundred KB at
    // most. Refuse anything far larger without reading it into memory: the
    // reported size first, then a bounded read (the size can be unknown).
    const tooLarge = ChatException(
      'invalid_backup',
      'Backup file is too large',
    );
    final int? length = file.lengthSync();
    if (length != null && length > maxBackupBytes) throw tooLarge;
    final BytesBuilder bytes = BytesBuilder(copy: false);
    await for (final Uint8List chunk in file.readAsByteStream()) {
      if (bytes.length + chunk.length > maxBackupBytes) throw tooLarge;
      bytes.add(chunk);
    }
    return (bytes: bytes.takeBytes(), name: file.name);
  }

  /// Largest file [pickBackup] will read.
  static const int maxBackupBytes = maxBackupFileBytes;
}

/// Test double: records what was saved and returns scripted picks.
final class FakeBackupFileGateway implements BackupFileGateway {
  FakeBackupFileGateway({
    this.saveResult = true,
    this.savePath,
    this.pickResult,
    this.pickName,
    this.pickError,
  });

  bool saveResult;
  String? savePath;
  Uint8List? pickResult;
  String? pickName;

  /// When set, [pickBackup] throws it (e.g. a file too large to be a backup).
  Object? pickError;
  Object? saveError;
  final List<Uint8List> saved = [];
  final List<String> savedNames = [];
  final List<Rect?> shareOrigins = [];

  @override
  Future<SavedBackup> saveBackup(
    Uint8List bytes, {
    required String fileName,
    Rect? shareOrigin,
  }) async {
    final error = saveError;
    if (error != null) throw error;
    saved.add(bytes);
    savedNames.add(fileName);
    shareOrigins.add(shareOrigin);
    return (completed: saveResult, path: saveResult ? savePath : null);
  }

  @override
  Future<PickedBackup?> pickBackup() async {
    final Object? error = pickError;
    if (error != null) throw error;
    final bytes = pickResult;
    return bytes == null ? null : (bytes: bytes, name: pickName);
  }
}
