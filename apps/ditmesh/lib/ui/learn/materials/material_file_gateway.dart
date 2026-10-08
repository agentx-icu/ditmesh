import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../i18n/current_strings.dart';

/// A file the learner picked: name and content.
final class PickedFile {
  const PickedFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Thrown when a picked file is larger than the caller's limit; nothing
/// beyond the size is read.
final class PickedFileTooLarge implements Exception {
  const PickedFileTooLarge(this.bytes);

  final int bytes;
}

/// Saving and picking material files (TXT/JSON/WAV). The platform split —
/// save dialog on desktop, share sheet on Android/iOS — lives here only, so
/// all five platforms have a save/share path and tests use a fake.
abstract interface class MaterialFileGateway {
  /// True when saved/shared, false when the user cancelled. Throws on I/O.
  Future<bool> save(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    Rect? shareOrigin,
  });

  /// Null when cancelled; throws [PickedFileTooLarge] above [maxBytes].
  Future<PickedFile?> pick({required int maxBytes});

  static MaterialFileGateway of(BuildContext context) {
    try {
      return context.read<MaterialFileGateway>();
    } on ProviderNotFoundException {
      return const PlatformMaterialFileGateway();
    }
  }
}

final class PlatformMaterialFileGateway implements MaterialFileGateway {
  const PlatformMaterialFileGateway();

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> save(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    Rect? shareOrigin,
  }) async {
    if (bytes.isEmpty) throw const FileSystemException('empty export');
    if (!_isMobile) {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        dialogTitle: currentS().materialsSaveDialogTitle,
      );
      return uri != null;
    }
    final dir = await Directory.systemTemp.createTemp('ditmesh_material_');
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mimeType, name: fileName)],
          sharePositionOrigin: shareOrigin,
        ),
      );
      return result.status != ShareResultStatus.dismissed;
    } finally {
      await dir.delete(recursive: true).then<void>((_) {}, onError: (_) {});
    }
  }

  @override
  Future<PickedFile?> pick({required int maxBytes}) async {
    final file = await FilePicker.pickFile(
      dialogTitle: currentS().materialsImportDialogTitle,
    );
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxBytes) throw PickedFileTooLarge(length);
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) throw PickedFileTooLarge(bytes.length);
    return PickedFile(file.name, bytes);
  }
}

/// Test double: scripted picks, recorded saves.
final class FakeMaterialFileGateway implements MaterialFileGateway {
  FakeMaterialFileGateway({this.pickResult, this.saveResult = true});

  PickedFile? pickResult;
  bool saveResult;
  Object? saveError;
  final List<(String, Uint8List)> saved = [];

  @override
  Future<bool> save(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    Rect? shareOrigin,
  }) async {
    final error = saveError;
    if (error != null) throw error;
    if (saveResult) saved.add((fileName, bytes));
    return saveResult;
  }

  @override
  Future<PickedFile?> pick({required int maxBytes}) async {
    final r = pickResult;
    if (r != null && r.bytes.length > maxBytes) {
      throw PickedFileTooLarge(r.bytes.length);
    }
    return r;
  }
}
