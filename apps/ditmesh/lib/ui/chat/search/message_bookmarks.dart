import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../../training/atomic_json_file.dart';

/// One bookmarked message: a reference only (profile is implied by the
/// file's directory). Unlike a training material it holds no copy of the
/// text, so clearing the conversation's history removes it too.
@immutable
final class MessageBookmark {
  const MessageBookmark({
    required this.conversationId,
    required this.messageId,
    required this.timestamp,
  });

  final String conversationId;
  final String messageId;
  final DateTime timestamp;

  Map<String, Object?> toJson() => <String, Object?>{
    'conversationId': conversationId,
    'messageId': messageId,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };

  static MessageBookmark? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final c = json['conversationId'];
    final m = json['messageId'];
    final t = DateTime.tryParse(json['timestamp'] as String? ?? '');
    if (c is! String || m is! String || t == null) return null;
    return MessageBookmark(conversationId: c, messageId: m, timestamp: t);
  }
}

/// Resolves the bookmark store of the current profile (provided by the app
/// scope, which knows the identity's data directory).
typedef BookmarksResolver = Future<MessageBookmarks> Function();

/// Local message bookmarks of one profile (functional spec §10.1), in
/// `<dataDirectory>/chat/bookmarks.json`. Writes are serialised and atomic.
class MessageBookmarks extends ChangeNotifier {
  MessageBookmarks._(this._file);

  /// Store for one profile ([profileKey] in [dataDirectory]); one instance
  /// per profile so every screen sees the same state. A replaced, deleted
  /// or switched identity retires its instance ([retireAll]): the backend
  /// may reuse the directory, and a stale cache must never be written over
  /// the next profile's file.
  static MessageBookmarks forProfile(String dataDirectory, String profileKey) {
    // While identity data is being replaced nothing may read or write the
    // old files: hand out a throw-away retired store.
    if (_blocked) return MessageBookmarks._(null).._retired = true;
    return _instances.putIfAbsent(
      '$dataDirectory#$profileKey',
      () => MessageBookmarks._(
        AtomicJsonFile(File(p.join(dataDirectory, 'chat', 'bookmarks.json'))),
      ),
    );
  }

  static bool _blocked = false;

  /// Durability barrier: every cached store's pending (or failed) writes.
  static Future<void> flushAll() async {
    for (final store in List.of(_instances.values)) {
      await store.flush();
    }
  }

  /// Flushes, then retires every cached store; the next [forProfile]
  /// reloads from disk. Retired stores ignore further changes.
  static Future<void> retireAll({bool block = false}) async {
    if (block) _blocked = true;
    final stores = List.of(_instances.values);
    _instances.clear();
    // Freeze first: from here on no store accepts a change...
    for (final store in stores) {
      store._retired = true;
    }
    // ...then let writes already in flight land, and give a snapshot that
    // failed earlier one last chance (it is the retiring profile's data).
    for (final store in stores) {
      try {
        await store._writes;
        if (store._dirty) await store._writeSnapshot();
      } on Object {
        // Retiring must not be blocked by a failing disk.
      }
    }
  }

  /// The replacement finished (a new identity is open): serve stores again.
  static void unblock() => _blocked = false;

  /// In-memory store for tests and stub identities.
  @visibleForTesting
  factory MessageBookmarks.memory() => MessageBookmarks._(null);

  static final Map<String, MessageBookmarks> _instances = {};

  /// In-memory fallbacks, one per chat service (so isolated screens and
  /// tests never share bookmarks across sessions).
  static final Expando<MessageBookmarks> _fallbacks = Expando();

  /// The current profile's loaded store; an in-memory one when the app
  /// provides no resolver (isolated screens, tests).
  static Future<MessageBookmarks> of(BuildContext context) async {
    BookmarksResolver? resolve;
    try {
      resolve = context.read<BookmarksResolver?>();
    } on ProviderNotFoundException {
      resolve = null;
    }
    final MessageBookmarks store;
    if (resolve != null) {
      store = await resolve();
    } else {
      Object key;
      try {
        key = context.read<ChatService>();
      } on ProviderNotFoundException {
        key = context;
      }
      store = _fallbacks[key] ??= MessageBookmarks._(null);
    }
    await store.load();
    return store;
  }

  final AtomicJsonFile? _file;
  final List<MessageBookmark> _items = <MessageBookmark>[];
  Future<void>? _loading;
  Future<void> _writes = Future<void>.value();

  /// The last write failed; the next change or [flush] writes again.
  bool _dirty = false;
  bool _retired = false;

  bool get isDirty => _dirty;

  List<MessageBookmark> get items => List.unmodifiable(_items);

  Future<void> load() =>
      _file == null ? Future<void>.value() : _loading ??= _load();

  Future<void> _load() async {
    final file = _file;
    if (file == null) return;
    try {
      final json = await file.read();
      final list = json?['bookmarks'];
      if (list is List) {
        _items
          ..clear()
          ..addAll(
            list.map(MessageBookmark.fromJson).whereType<MessageBookmark>(),
          );
      }
    } on Object {
      // An unreadable file starts empty; the next write replaces it.
    }
    notifyListeners();
  }

  bool contains(String conversationId, String messageId) => _items.any(
    (b) => b.conversationId == conversationId && b.messageId == messageId,
  );

  List<MessageBookmark> inConversation(String conversationId) =>
      _items.where((b) => b.conversationId == conversationId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  Future<void> toggle(String conversationId, String messageId, DateTime at) {
    if (_retired) return Future<void>.value();
    if (contains(conversationId, messageId)) {
      _items.removeWhere(
        (b) => b.conversationId == conversationId && b.messageId == messageId,
      );
    } else {
      _items.add(
        MessageBookmark(
          conversationId: conversationId,
          messageId: messageId,
          timestamp: at,
        ),
      );
    }
    return _save();
  }

  /// Clearing a conversation's history invalidates its bookmarks.
  Future<void> removeConversation(String conversationId) {
    if (_retired) return Future<void>.value();
    final before = _items.length;
    _items.removeWhere((b) => b.conversationId == conversationId);
    return before == _items.length ? Future<void>.value() : _save();
  }

  /// Drops bookmarks of messages that no longer exist.
  Future<void> removeMissing(String conversationId, Set<String> missing) {
    if (_retired) return Future<void>.value();
    final before = _items.length;
    _items.removeWhere(
      (b) =>
          b.conversationId == conversationId && missing.contains(b.messageId),
    );
    return before == _items.length ? Future<void>.value() : _save();
  }

  /// Waits for pending writes and retries a failed one.
  Future<void> flush() async {
    await _writes;
    if (_dirty && !_retired) await _write();
  }

  Future<void> _save() {
    notifyListeners();
    return _write();
  }

  /// Whether this store was retired (profile changed or replaced); callers
  /// holding it should resolve the current one again.
  bool get isRetired => _retired;

  /// Writes the current snapshot (every write is a full snapshot, so a
  /// retry after a failure needs no replay).
  Future<void> _writeSnapshot() => _write();

  Future<void> _write() {
    final file = _file;
    if (file == null) return Future<void>.value();
    final snapshot = <String, Object?>{
      'v': 1,
      'bookmarks': [for (final b in _items) b.toJson()],
    };
    final write = _writes
        .then((_) => file.write(snapshot))
        .then(
          (_) => _dirty = false,
          onError: (Object e, StackTrace st) {
            _dirty = true;
            Error.throwWithStackTrace(e, st);
          },
        );
    _writes = write.then<void>((_) {}, onError: (Object _) {});
    return write;
  }
}

/// Registered with the identity service: the bookmark files are flushed
/// before backup and retired before the identity's data is replaced, and
/// retired again whenever the open identity changes.
final class MessageBookmarksBarrier implements IdentityDataStore {
  MessageBookmarksBarrier(this._identity) {
    _key = _identity.current?.publicKey;
    _sub = _identity.identityChanges.listen((identity) {
      // Only a different (or no) profile retires the stores; a name or
      // password change keeps them.
      final key = identity?.publicKey;
      if (identity != null) MessageBookmarks.unblock();
      if (key == _key) return;
      _key = key;
      MessageBookmarks.retireAll().ignore();
    });
    final identity = _identity;
    if (identity is PersistentIdentityService) identity.registerDataStore(this);
  }

  final IdentityService _identity;
  late final StreamSubscription<Identity?> _sub;
  String? _key;

  @override
  Future<void> flush() => MessageBookmarks.flushAll();

  @override
  Future<void> prepareForReplacement() {
    // A restore may reopen the same key: force the next change to count.
    _key = null;
    return MessageBookmarks.retireAll(block: true);
  }

  void dispose() {
    final identity = _identity;
    if (identity is PersistentIdentityService) {
      identity.unregisterDataStore(this);
    }
    _sub.cancel().ignore();
  }
}
