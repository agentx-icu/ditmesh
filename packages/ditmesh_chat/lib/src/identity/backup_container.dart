import 'dart:convert';
import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// The ditmesh identity backup container (`IdentityService.exportBackup`).
///
/// A dependency-free, length-prefixed archive. Layout (all integers
/// big-endian):
///
/// ```text
/// magic      4 bytes   "MCQB"
/// version    u8        1
/// flags      u8        bit0 = tox_profile.tox entry is passphrase-encrypted
/// count      u32       number of entries
/// entry*     u16 pathLength, path (UTF-8, '/'-separated),
///            u64 size, bytes
/// ```
///
/// Entries written by the identity service:
///   * `identity.json`     display name / status / Tox ID / hasPassword
///   * `tox_profile.tox`   Tox savedata, encrypted with the identity password
///                         when one is set (so a lost backup is as safe as
///                         the profile on disk)
///   * `training/<path>`   every file under `dataDirectory()` (morse_trainer
///                         progress and anything else other modules stored)
///   * `media/recordings/<name>`  saved workbench recordings, only when the
///                         learner opted in on export. Additive: older
///                         versions decode the container and ignore them.
///
/// A container is not itself encrypted: the profile inside is, and the
/// training data is not secret. Paths are validated on decode (no `..`, no
/// absolute paths, no backslashes) so a hostile archive cannot escape the
/// identity root on restore.
///
/// Version 2 is the same layout used only as the *inner* archive of an
/// encrypted backup (`backup_envelope.dart`), adding a private
/// `manifest.json` and the chat / metadata / preference / pending entries
/// listed in `backup_snapshot.dart`. A bare v2 container is never accepted
/// as a legacy backup.
class BackupContainer {
  BackupContainer({
    required this.entries,
    required this.profileEncrypted,
    this.formatVersion = version,
  });

  static const int version = 1;
  static const int innerVersion = 2;

  /// Most entries a container may declare; real ones hold a few hundred.
  static const int maxEntries = 100000;
  static const List<int> magic = [0x4D, 0x43, 0x51, 0x42]; // "MCQB"
  static const String identityEntry = 'identity.json';
  static const String profileEntry = 'tox_profile.tox';
  static const String trainingPrefix = 'training/';
  static const String mediaPrefix = 'media/recordings/';

  /// Archive path → bytes, in insertion order.
  final Map<String, Uint8List> entries;
  final bool profileEncrypted;
  final int formatVersion;

  Uint8List? get profile => entries[profileEntry];
  Uint8List? get identity => entries[identityEntry];

  Iterable<MapEntry<String, Uint8List>> get trainingFiles =>
      entries.entries.where((e) => e.key.startsWith(trainingPrefix));

  /// Recordings: plain file names directly under [mediaPrefix].
  Iterable<MapEntry<String, Uint8List>> get mediaFiles => entries.entries.where(
    (e) =>
        e.key.startsWith(mediaPrefix) &&
        !e.key.substring(mediaPrefix.length).contains('/'),
  );

  Uint8List encode() {
    final out = BytesBuilder(copy: false);
    out.add(magic);
    out.addByte(formatVersion);
    out.addByte(profileEncrypted ? 1 : 0);
    out.add(_u32(entries.length));
    for (final e in entries.entries) {
      final path = utf8.encode(e.key);
      if (path.length > 0xFFFF) {
        throw ChatException('invalid_backup', 'Path too long: ${e.key}');
      }
      out.add(_u16(path.length));
      out.add(path);
      out.add(_u64(e.value.length));
      out.add(e.value);
    }
    return out.toBytes();
  }

  /// Largest archive [decode] accepts. Real ones are a few hundred KB, but
  /// opt-in recordings may add up to [BackupMedia.maxBytes].
  static const int maxBytes = maxBackupFileBytes;

  /// Decodes a legacy (v1) backup, or with [inner] the v2 archive found
  /// inside an encrypted envelope. Duplicate paths, unsafe paths, entry
  /// counts above [maxEntries] and trailing bytes are rejected.
  static BackupContainer decode(Uint8List bytes, {bool inner = false}) {
    const invalid = ChatException('invalid_backup', 'Not a ditmesh backup');
    if (bytes.length < 10 || bytes.length > maxBytes) throw invalid;
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != magic[i]) throw invalid;
    }
    final data = ByteData.sublistView(bytes);
    final ver = data.getUint8(4);
    if (ver != (inner ? innerVersion : version)) {
      throw ChatException(
        'unsupported_backup_version',
        'Backup version $ver is newer than this app supports',
      );
    }
    final flags = data.getUint8(5);
    final count = data.getUint32(6, Endian.big);
    if (count > maxEntries) throw invalid;
    var offset = 10;
    final entries = <String, Uint8List>{};
    for (var i = 0; i < count; i++) {
      if (offset + 2 > bytes.length) throw invalid;
      final pathLen = data.getUint16(offset, Endian.big);
      offset += 2;
      if (offset + pathLen + 8 > bytes.length) throw invalid;
      final String path;
      try {
        path = utf8.decode(bytes.sublist(offset, offset + pathLen));
      } on FormatException {
        throw invalid;
      }
      offset += pathLen;
      final size = data.getUint64(offset, Endian.big);
      offset += 8;
      // Compared against what is left, never `offset + size`: a size near
      // 2^63 would overflow the sum and slip past the bound.
      if (size < 0 || size > bytes.length - offset) throw invalid;
      if (!isSafeArchivePath(path)) {
        throw ChatException('invalid_backup', 'Unsafe entry path: $path');
      }
      if (entries.containsKey(path)) {
        throw ChatException('invalid_backup', 'Duplicate entry: $path');
      }
      entries[path] = Uint8List.sublistView(bytes, offset, offset + size);
      offset += size;
    }
    // A v2 archive is sealed whole, so trailing bytes there mean tampering
    // by the writer; v1 files keep the lenient reading they always had.
    if (inner && offset != bytes.length) throw invalid;
    return BackupContainer(
      entries: entries,
      profileEncrypted: flags & 1 == 1,
      formatVersion: ver,
    );
  }

  /// Relative, '/'-separated, no empty / `.` / `..` segments, no backslashes.
  static bool isSafeArchivePath(String path) {
    if (path.isEmpty ||
        path.startsWith('/') ||
        path.contains('\\') ||
        path.contains(':')) {
      return false;
    }
    if (path.contains('\u0000')) return false;
    for (final seg in path.split('/')) {
      if (seg.isEmpty || seg == '.' || seg == '..') return false;
    }
    return true;
  }

  static Uint8List _u16(int v) =>
      Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.big);
  static Uint8List _u32(int v) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.big);
  static Uint8List _u64(int v) =>
      Uint8List(8)..buffer.asByteData().setUint64(0, v, Endian.big);
}
