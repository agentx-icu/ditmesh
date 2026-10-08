import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as pkgffi;
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

/// A Tox public key / address pair for tests.
const String kSelfKey =
    '1111111111111111111111111111111111111111111111111111111111111111';
// 0x11 x 32 and a zero nospam cancel out: checksum 0000.
const String kSelfToxId = '${kSelfKey}000000000000';
const String kPeerKey =
    '2222222222222222222222222222222222222222222222222222222222222222';
// Tox address = key + nospam + checksum (XOR of the 36 bytes in two lanes);
// for 0x22 x 32 + zero nospam both lanes cancel out, so the checksum is 0000.
// A wrong checksum is refused by tox_friend_add (TOX_ERR_FRIEND_ADD_BAD_CHECKSUM).
const String kPeerToxId = '${kPeerKey}000000000000';

/// Deterministic `Tim2ToxFfi` binding fake, the way tim2tox's own tests do it
/// (`Tim2ToxFfi.forTesting` + override each `late final` binding as a getter).
/// Covers exactly what the headless chat-service tests exercise; anything
/// else throws the base class's lookup error, which is what we want.
class FakeTim2ToxFfi extends Tim2ToxFfi {
  FakeTim2ToxFfi() : super.forTesting();

  /// `(userId, nick, online)` rows returned by [getFriendList].
  final List<({String userId, String nick, bool online})> friends = [];

  /// `(userId, wording)` rows returned as pending friend applications.
  final List<({String userId, String wording})> applications = [];

  String selfToxId = kSelfToxId;
  int uninitCalls = 0;

  int _writeString(String s, ffi.Pointer<ffi.Int8> buf, int cap) {
    final bytes = utf8.encode(s);
    if (bytes.length + 1 > cap) return -(bytes.length + 1);
    final out = buf.cast<ffi.Uint8>().asTypedList(bytes.length + 1);
    out.setAll(0, bytes);
    out[bytes.length] = 0;
    return bytes.length;
  }

  @override
  int Function() get getCurrentInstanceId => () => 0;

  @override
  void Function() get uninit => () => uninitCalls++;

  @override
  void Function() get saveToxProfile => () {};

  @override
  int Function() get getSelfConnectionStatus => () => 0;

  @override
  int Function(int) get isInstanceInitialized => (_) => 0;

  @override
  int Function(ffi.Pointer<ffi.Int8>, int) get getSelfToxId =>
      (buf, cap) => _writeString(selfToxId, buf, cap);

  @override
  int Function(ffi.Pointer<ffi.Int8>, int) get getFriendList => (buf, cap) {
        if (friends.isEmpty) return 0;
        final lines = [
          for (final f in friends) '${f.userId}\t${f.nick}\t${f.online ? 1 : 0}',
        ].join('\n');
        return _writeString(lines, buf, cap);
      };

  /// When set, reading the pending friend applications throws (a failing
  /// FFI read).
  bool failApplications = false;

  @override
  int Function(int, ffi.Pointer<ffi.Int8>, int)
      get getFriendApplicationsForInstance => (_, buf, cap) {
            if (failApplications) throw StateError('applications read failed');
            if (applications.isEmpty) return 0;
            final lines = [
              for (final a in applications) '${a.userId}\t${a.wording}',
            ].join('\n');
            return _writeString(lines, buf, cap);
          };

  @override
  int Function(int, ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<ffi.Int8>, int)
      get getGroupNameNative => (_, _, _, _) => 0;

  @override
  int Function(int, ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<ffi.Int8>, int)
      get getGroupChatIdNative => (_, _, _, _) => 0;

  /// Addresses handed to `tim2tox_ffi_add_friend`; the sync dispatch
  /// "succeeds" and the async `friendAddResult` is left to the test.
  final List<String> addedFriends = [];

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<pkgffi.Utf8>)
      get addFriend => (address, _) {
            addedFriends.add(address.toDartString());
            return 1;
          };

  /// Session epoch per instance, for the notification ownership check.
  int sessionEpoch = 1;

  @override
  int Function(int) get getSessionEpoch => (_) => sessionEpoch;

  /// Peers handed to the native C2C text sends (plain, `_ex`, action);
  /// each "succeeds". A note to self must never appear here.
  final List<String> sentTextPeers = [];

  /// When set, every C2C text send throws (a drain then marks the queued
  /// row failed).
  bool failSends = false;

  int _recordSend(ffi.Pointer<pkgffi.Utf8> peer) {
    if (failSends) throw StateError('fake: native send failed');
    sentTextPeers.add(peer.toDartString());
    return 1;
  }

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<pkgffi.Utf8>)
      get sendText => (peer, _) => _recordSend(peer);

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<pkgffi.Utf8>,
          ffi.Pointer<ffi.Int8>, int)
      get sendTextEx => (peer, _, out, _) {
            out[0] = 0; // no native message id
            return _recordSend(peer);
          };

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>, ffi.Pointer<pkgffi.Utf8>,
          ffi.Pointer<ffi.Int8>, int)
      get sendC2CActionEx => (peer, _, out, _) {
            out[0] = 0; // no native message id
            return _recordSend(peer);
          };

  /// Public keys handed to `tim2tox_ffi_delete_friend`; always "succeeds".
  final List<String> deletedFriends = [];

  @override
  int Function(ffi.Pointer<pkgffi.Utf8>) get deleteFriend => (key) {
        deletedFriends.add(key.toDartString());
        return 1;
      };
}

/// `ChatEngine` stand-in: never touches the native library. Tests hand it the
/// `FfiChatService` (built on a [FakeTim2ToxFfi]) that `start` should expose.
///
/// Models native profile persistence the way Tim2Tox does it: with a
/// passphrase, `start` opens an encrypted profile (refusing a wrong or
/// missing one) and writes the profile back encrypted (migrating a plaintext
/// file), `createProfile` writes it encrypted, and a re-key rewrites it.
class FakeChatEngine extends ChatEngine {
  FakeChatEngine({this.serviceToStart, FakeProfileCrypto? crypto})
    : crypto = crypto ?? FakeProfileCrypto();

  final FakeProfileCrypto crypto;

  /// What the next [rekeyProfilePassphrase] calls answer (false: the native
  /// write failed and the file keeps the old passphrase).
  final List<bool> rekeyResults = [];
  final List<String?> rekeyCalls = [];
  EngineSessionConfig? _running;
  String? _livePassphrase;

  FfiChatService? serviceToStart;
  FfiChatService? _service;
  final StreamController<FfiChatService?> _sessions =
      StreamController.broadcast();
  final StreamController<bool> _conn = StreamController.broadcast();
  bool _connected = false;

  final List<EngineSessionConfig> startCalls = [];
  int stopCalls = 0;
  int saveCalls = 0;
  final List<(String, String)> profileUpdates = [];

  /// The key `createProfile` mints (a 76-hex Tox address).
  String nextToxId = kSelfToxId;

  @override
  FfiChatService? get service => _service;

  @override
  Stream<FfiChatService?> get sessionChanges =>
      Stream.multi((e) {
        e.add(_service);
        final sub = _sessions.stream.listen(e.add);
        e.onCancel = sub.cancel;
      });

  @override
  bool get isConnected => _connected;

  @override
  Stream<bool> get connectionChanges => _conn.stream;

  void setConnected(bool value) {
    _connected = value;
    _conn.add(value);
  }

  @override
  Future<String> createProfile({
    required IdentityPaths paths,
    required String displayName,
    required String statusMessage,
    String? passphrase,
  }) async {
    await paths.ensureDirectories();
    final plain = FakeProfileCrypto.plainProfile(
      nextToxId.substring(0, 64),
      displayName,
    );
    await File(paths.profileFile).writeAsBytes(
      passphrase == null ? plain : crypto.encrypt(plain, passphrase),
    );
    return nextToxId;
  }

  @override
  Future<void> start(EngineSessionConfig config) async {
    startCalls.add(config);
    final file = File(config.paths.profileFile);
    final pass = config.profilePassphrase;
    if (file.existsSync()) {
      var bytes = file.readAsBytesSync();
      if (crypto.isEncrypted(bytes)) {
        if (pass == null) {
          throw const ChatException('needs_passphrase', 'fake: encrypted');
        }
        bytes = crypto.decrypt(bytes, pass); // throws on a wrong one
      }
      // The first native save after load: encrypted when a passphrase is set.
      file.writeAsBytesSync(pass == null ? bytes : crypto.encrypt(bytes, pass));
    }
    _running = config;
    _livePassphrase = pass;
    _service = serviceToStart;
    _sessions.add(_service);
  }

  @override
  bool rekeyProfilePassphrase(String? passphrase) {
    rekeyCalls.add(passphrase);
    final config = _running;
    if (config == null) return false;
    if (rekeyResults.isNotEmpty && !rekeyResults.removeAt(0)) return false;
    final file = File(config.paths.profileFile);
    var bytes = file.readAsBytesSync();
    final live = _livePassphrase;
    if (crypto.isEncrypted(bytes) && live != null) {
      bytes = crypto.decrypt(bytes, live);
    }
    file.writeAsBytesSync(
      passphrase == null ? bytes : crypto.encrypt(bytes, passphrase),
    );
    _livePassphrase = passphrase;
    return true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _running = null;
    _livePassphrase = null;
    _service = null;
    _sessions.add(null);
    setConnected(false);
  }

  /// Binds [svc] directly (chat-service tests that skip the identity layer).
  void bind(FfiChatService? svc) {
    _service = svc;
    _sessions.add(svc);
  }

  @override
  Future<void> updateSelfProfile(String displayName, String statusMessage) async {
    profileUpdates.add((displayName, statusMessage));
  }

  @override
  void saveProfileNow() => saveCalls++;

  @override
  Future<void> dispose() async {
    await _sessions.close();
    await _conn.close();
  }
}

/// In-memory store whose writes can be parked on a completer. Lets a test
/// freeze a refresh or a mutation at a real `await` (Tim2Tox's nickname
/// cache write, our queued-invite / hidden-set write), detach the session
/// underneath it, then release it and check that nothing stale is published.
class HoldingKeyValueStore extends MemoryKeyValueStore {
  /// While set, every [setString] waits for it before writing.
  Completer<void>? holdSetString;

  /// While set, every [setStringList] waits for it before writing.
  Completer<void>? holdSetStringList;

  int stringListWrites = 0;

  /// When set, only writes whose key contains this text are held; the rest
  /// stay synchronous (lets a test park our meta-store write and not the
  /// Tim2Tox prefs write that precedes it).
  String? holdOnlyKeyContaining;

  bool _holds(String key) {
    final only = holdOnlyKeyContaining;
    return only == null || key.contains(only);
  }

  /// Completes when a write first reaches [holdSetString]; a test awaits it
  /// instead of guessing a delay before detaching.
  Completer<void> heldString = Completer<void>();

  /// Same for [holdSetStringList].
  Completer<void> heldStringList = Completer<void>();

  // Unheld writes stay synchronous like the base class (and like
  // SharedPreferences' in-memory cache): a read right after the call sees
  // the value. Only a held write is deferred.
  @override
  Future<void> setString(String key, String value) {
    final hold = holdSetString;
    if (hold == null || !_holds(key)) return super.setString(key, value);
    if (!heldString.isCompleted) heldString.complete();
    return hold.future.then((_) => super.setString(key, value));
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    stringListWrites++;
    final hold = holdSetStringList;
    if (hold == null || !_holds(key)) {
      return super.setStringList(key, value);
    }
    if (!heldStringList.isCompleted) heldStringList.complete();
    return hold.future.then((_) => super.setStringList(key, value));
  }
}

/// Reversible "encryption" with a recognisable header, and a plaintext
/// profile format the extractor can read. Keeps the identity state machine
/// testable without libtim2tox_ffi.
class FakeProfileCrypto implements ProfileCrypto {
  static const _magic = 'FAKEENC:';
  static const _profileMagic = 'TOXPROFILE:';

  static Uint8List plainProfile(String publicKey, String name) =>
      Uint8List.fromList(utf8.encode('$_profileMagic$publicKey:$name'));

  @override
  bool isEncrypted(Uint8List data) =>
      data.length >= _magic.length &&
      utf8.decode(data.sublist(0, _magic.length), allowMalformed: true) ==
          _magic;

  @override
  Uint8List encrypt(Uint8List plaintext, String password) =>
      Uint8List.fromList(
        utf8.encode('$_magic$password:') + plaintext,
      );

  @override
  Uint8List decrypt(Uint8List ciphertext, String password) {
    final text = utf8.decode(ciphertext, allowMalformed: true);
    final prefix = '$_magic$password:';
    if (!text.startsWith(prefix)) {
      throw const ChatException('wrong_password', 'fake: wrong password');
    }
    return Uint8List.fromList(ciphertext.sublist(utf8.encode(prefix).length));
  }

  @override
  String extractPublicKey(Uint8List plaintext) {
    final text = utf8.decode(plaintext, allowMalformed: true);
    if (!text.startsWith(_profileMagic)) {
      throw const ChatException('invalid_profile', 'fake: not a profile');
    }
    return text.substring(_profileMagic.length, _profileMagic.length + 64);
  }
}

/// A headless `FfiChatService` over [ffi], the way toxee's tests build one.
Future<FfiChatService> newEngineService(
  FakeTim2ToxFfi ffi,
  KeyValueStore store,
  Directory root,
  String dirName,
) async {
  final paths = IdentityPaths('${root.path}/$dirName');
  await paths.ensureDirectories();
  return FfiChatService(
    ffiForTesting: ffi,
    preferencesService:
        Tim2ToxPreferencesAdapter(store, accountPrefix: '1111111111111111'),
    historyDirectory: paths.historyDirectory,
    queueFilePath: paths.offlineQueueFile,
    fileRecvPath: paths.fileRecvDirectory,
    avatarsPath: paths.avatarsDirectory,
  )
    ..debugBeginSessionForTest()
    ..debugNativePendingInvitesOverride = () => const [];
}
