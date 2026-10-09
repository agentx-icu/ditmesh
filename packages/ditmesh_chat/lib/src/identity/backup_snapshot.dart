import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';

import 'identity_paths.dart';

/// One unsent message found in the durable outbox at export time.
final class QueuedRow {
  const QueuedRow({
    required this.queueKey,
    required this.conversationId,
    required this.text,
    required this.queuedAt,
    this.msgId,
  });

  /// Tim2Tox queue slot: a peer key, or `group:<id>`.
  final String queueKey;

  /// Contract id (`c2c_<KEY>` / `group_<id>`).
  final String conversationId;
  final String text;
  final DateTime queuedAt;
  final String? msgId;

  /// History file id this row belongs to (peer key or group id).
  String get historyId => queueKey.startsWith('group:')
      ? queueKey.substring('group:'.length)
      : queueKey;

  /// [index] keeps legacy rows without a durable id apart, even when two
  /// were queued in the same microsecond.
  RestoredPendingItem toItem(int index) => RestoredPendingItem(
    id: msgId ?? 'q_${queuedAt.microsecondsSinceEpoch}_$index',
    conversationId: conversationId,
    text: text,
    queuedAt: queuedAt,
  );
}

/// Data changed while it was being read; the caller retries the snapshot.
final class SnapshotUnstable implements Exception {
  const SnapshotUnstable(this.path);
  final String path;
}

/// Layout of the inner (v2) archive of an encrypted backup and the file
/// walks that build and check it. Pure file logic; the identity service
/// owns sequencing (persist, pause networking, retry, staging).
///
/// ```text
/// manifest.json              private manifest (categories, sizes, counts)
/// identity.json              identity record
/// tox_profile.tox            Tox savedata (identity-password encrypted iff set)
/// groups/bindings.json       group membership: ids, chat ids, kinds, names
///                            (identity category; absent when no groups)
/// training/<path>            training files, minus training/chat/{bookmarks,
///                            restored_pending}.json
/// chat/history/<path>        native history, queued rows removed
/// meta/conversations.json    pins, hidden conversations, drafts
/// meta/bookmarks.json        message bookmarks
/// prefs/app.json             the app's portable preferences document
/// media/recordings/<name>    opt-in recordings
/// pending/outbox.json        opt-in unsent messages (review items)
/// ```
abstract final class BackupSnapshot {
  static const String manifestEntry = 'manifest.json';
  static const String groupsEntry = 'groups/bindings.json';
  static const String trainingPrefix = 'training/';
  static const String historyPrefix = 'chat/history/';
  static const String conversationsEntry = 'meta/conversations.json';
  static const String bookmarksEntry = 'meta/bookmarks.json';
  static const String preferencesEntry = 'prefs/app.json';
  static const String mediaPrefix = 'media/recordings/';
  static const String pendingEntry = 'pending/outbox.json';
  static const String manifestFormat = 'ditmesh-backup';

  /// Training-relative files that belong to other categories.
  static const String bookmarksFile = 'chat/bookmarks.json';
  static const String restoredPendingFile = restoredPendingDoc;

  static final RegExp _mediaName = RegExp(
    r'^[A-Za-z0-9_\-]+(?:\.[A-Za-z0-9]+)?$',
  );

  /// Category an inner-archive [path] belongs to; null when no category
  /// may hold it (the archive is then rejected).
  static BackupCategory? categoryOf(String path) {
    if (path == manifestEntry) return BackupCategory.identity;
    if (path == 'identity.json' ||
        path == 'tox_profile.tox' ||
        path == groupsEntry) {
      return BackupCategory.identity;
    }
    if (path.startsWith(trainingPrefix)) {
      final rel = path.substring(trainingPrefix.length);
      if (rel == bookmarksFile || rel == restoredPendingFile) return null;
      return BackupCategory.training;
    }
    if (path.startsWith(historyPrefix)) return BackupCategory.chatHistory;
    if (path == conversationsEntry || path == bookmarksEntry) {
      return BackupCategory.conversationMeta;
    }
    if (path == preferencesEntry) return BackupCategory.preferences;
    if (path.startsWith(mediaPrefix)) {
      final name = path.substring(mediaPrefix.length);
      return _mediaName.hasMatch(name) && name != 'current.wav'
          ? BackupCategory.media
          : null;
    }
    if (path == pendingEntry) return BackupCategory.pendingMessages;
    return null;
  }

  // ---- outbox ----------------------------------------------------------------

  /// The durable outbox, read from a private copy of the queue files so the
  /// loader's own recovery writes never touch the live identity.
  static Future<List<QueuedRow>> readQueue(IdentityPaths paths) async {
    final source = File(paths.offlineQueueFile);
    final backup = File('${paths.offlineQueueFile}.bak');
    if (!await source.exists() && !await backup.exists()) return const [];
    final temp = await Directory.systemTemp.createTemp('ditmesh-queue-');
    try {
      final copy = p.join(temp.path, 'queue.json');
      if (await source.exists()) await source.copy(copy);
      if (await backup.exists()) await backup.copy('$copy.bak');
      final queue = await OfflineMessageQueuePersistence(
        queueFilePath: copy,
      ).loadQueue();
      final out = <QueuedRow>[];
      final seen = <String>{};
      for (final entry in queue.entries) {
        final key = entry.key;
        final conv = key.startsWith('group:')
            ? 'group_${key.substring('group:'.length)}'
            : 'c2c_${key.toUpperCase()}';
        for (final item in entry.value) {
          final id = item.msgID;
          if (id != null && id.isNotEmpty && !seen.add('$key/$id')) continue;
          out.add(
            QueuedRow(
              queueKey: key,
              conversationId: conv,
              text: item.text,
              queuedAt: item.timestamp,
              msgId: id == null || id.isEmpty ? null : id,
            ),
          );
        }
      }
      return out;
    } on OfflineMessageQueueCorruptionException {
      throw const ChatException(
        'invalid_backup',
        'The unsent-message queue is unreadable',
      );
    } finally {
      await temp.delete(recursive: true);
    }
  }

  /// [queue] without the rows the user already withdrew (a removed or
  /// blocked friend's queue, a refused send) whose cancel had not persisted
  /// yet: [withdrawals] are `peer\tmessageId` entries of the identity's
  /// `ditmesh_pending_withdrawals`. Those rows are not unsent messages; a
  /// restore must not offer them for review again. Matched on the C2C
  /// queue key (case-insensitive) and the durable id together.
  static List<QueuedRow> withoutWithdrawn(
    List<QueuedRow> queue,
    Set<String> withdrawals,
  ) {
    if (withdrawals.isEmpty) return queue;
    final withdrawn = {
      for (final entry in withdrawals)
        if (entry.indexOf('\t') case final tab when tab > 0)
          '${entry.substring(0, tab).trim().toUpperCase()}\t'
              '${entry.substring(tab + 1)}',
    };
    return [
      for (final row in queue)
        if (row.queueKey.startsWith('group:') ||
            row.msgId == null ||
            !withdrawn.contains(
              '${row.queueKey.trim().toUpperCase()}\t${row.msgId}',
            ))
          row,
    ];
  }

  // ---- file walks ----------------------------------------------------------

  /// Regular files under [dir] (no symlinks followed), sorted, as
  /// '/'-separated paths relative to it. Transient `.tmp` / `.bak` files of
  /// atomic writers are skipped.
  static Future<List<(String, File)>> files(String dir) async {
    final root = Directory(dir);
    if (!await root.exists()) return const [];
    final out = <(String, File)>[];
    await for (final e in root.list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final name = p.basename(e.path);
      if (name.endsWith('.tmp') || name.endsWith('.bak')) continue;
      final rel = p.url.joinAll(p.split(p.relative(e.path, from: dir)));
      out.add((rel, e));
    }
    out.sort((a, b) => a.$1.compareTo(b.$1));
    return out;
  }

  /// Size and modification time of every file read, for [verifyStable].
  static Future<Map<String, (int, DateTime)>> stamp(
    Iterable<File> files,
  ) async => {
    for (final f in files)
      f.path: (await f.length(), await f.lastModified()),
  };

  /// Throws [SnapshotUnstable] when a file read for the snapshot changed or
  /// vanished, or when the same selection made again ([now]) finds a file
  /// that was not read.
  static Future<void> verifyStable(
    Map<String, (int, DateTime)> before,
    Iterable<File> now,
  ) async {
    for (final path in {...before.keys, for (final f in now) f.path}) {
      final was = before[path];
      final file = File(path);
      if (was == null || !await file.exists()) throw SnapshotUnstable(path);
      if (await file.length() != was.$1 ||
          await file.lastModified() != was.$2) {
        throw SnapshotUnstable(path);
      }
    }
  }

  // ---- history ---------------------------------------------------------------

  /// [bytes] of a native history file with every row still in the outbox
  /// removed (a restored "sent" row that never left would be a false
  /// claim). Unparseable files and files without queued rows pass through
  /// unchanged. Returns the bytes and how many rows were removed.
  static (Uint8List, int) withoutQueued(
    String relPath,
    Uint8List bytes,
    List<QueuedRow> queued,
  ) {
    if (queued.isEmpty) return (bytes, 0);
    if (relPath.endsWith('.archive.jsonl')) {
      return _filterJsonl(bytes, queued);
    }
    if (!relPath.endsWith('.json')) return (bytes, 0);
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return (bytes, 0);
    }
    if (decoded is! Map || decoded['messages'] is! List) return (bytes, 0);
    final conv = '${decoded['conversationId'] ?? ''}';
    final mine = _queuedFor(conv, queued);
    if (mine.isEmpty) return (bytes, 0);
    final rows = decoded['messages'] as List;
    final kept = rows.where((r) => !_isQueuedRow(r, mine)).toList();
    if (kept.length == rows.length) return (bytes, 0);
    final out = Map<String, Object?>.from(decoded)..['messages'] = kept;
    return (
      Uint8List.fromList(utf8.encode(jsonEncode(out))),
      rows.length - kept.length,
    );
  }

  static (Uint8List, int) _filterJsonl(Uint8List bytes, List<QueuedRow> all) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      return (bytes, 0);
    }
    var removed = 0;
    final kept = <String>[];
    for (final line in const LineSplitter().convert(text)) {
      Object? row;
      try {
        row = line.trim().isEmpty ? null : jsonDecode(line);
      } on FormatException {
        row = null;
      }
      // Archive rows carry no conversation id for C2C; match on id/content
      // across every queued row (ids are unique, legacy needs text + time).
      if (_isQueuedRow(row, all)) {
        removed++;
        continue;
      }
      kept.add(line);
    }
    if (removed == 0) return (bytes, 0);
    final joined = kept.isEmpty ? '' : '${kept.join('\n')}\n';
    return (Uint8List.fromList(utf8.encode(joined)), removed);
  }

  static List<QueuedRow> _queuedFor(String historyId, List<QueuedRow> all) {
    final id = historyId.toUpperCase();
    return all.where((q) => q.historyId.toUpperCase() == id).toList();
  }

  static bool _isQueuedRow(Object? row, List<QueuedRow> queued) {
    if (row is! Map || row['isSelf'] != true) return false;
    final id = row['msgID'];
    final at = DateTime.tryParse('${row['timestamp']}');
    for (final q in queued) {
      if (q.msgId != null) {
        if (id == q.msgId) return true;
        continue;
      }
      // Legacy queue items predate durable ids: same rule as the live
      // PendingMessageStatus matcher (enqueue time and text).
      if (at != null &&
          at.millisecondsSinceEpoch == q.queuedAt.millisecondsSinceEpoch &&
          row['text'] == q.text) {
        return true;
      }
    }
    return false;
  }

  // ---- documents -------------------------------------------------------------

  static Uint8List encodeJson(Object? value) =>
      Uint8List.fromList(utf8.encode(jsonEncode(value)));

  static Object? decodeJson(Uint8List bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ChatException('invalid_backup', 'Malformed backup document');
    }
  }

  /// Review items from [bytes] (`pending/outbox.json` or a previously
  /// restored document); malformed entries are dropped.
  static List<RestoredPendingItem> pendingItems(Uint8List? bytes) {
    if (bytes == null) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return const [];
    }
    final list = decoded is Map ? decoded['items'] : decoded;
    if (list is! List) return const [];
    return [
      for (final e in list) ?RestoredPendingItem.fromJson(e),
    ];
  }

  static Uint8List encodePending(List<RestoredPendingItem> items) =>
      encodeJson({'items': [for (final i in items) i.toJson()]});
}
