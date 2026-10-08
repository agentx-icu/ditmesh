import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_features.dart';
import 'package:ditmesh/di/backend_factory.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

void main() {
  test(
    'native preparation failure never resolves to a fake chat backend',
    () async {
      final native = _UnavailableBackend();
      await expectLater(
        resolveBackendFactory(const AppFeatures(), nativeFactory: native),
        throwsA(isA<StateError>()),
      );
      expect(native.prepared, isTrue);
    },
  );

  test('native preparation exceptions retain their diagnostic cause', () async {
    final cause = StateError('libtim2tox_ffi could not be loaded');
    await expectLater(
      resolveBackendFactory(
        const AppFeatures(),
        nativeFactory: _UnavailableBackend(error: cause),
      ),
      throwsA(same(cause)),
    );
  });

  test('available native backend is preserved', () async {
    final native = FakeBackendFactory();
    final resolved = await resolveBackendFactory(
      const AppFeatures(),
      nativeFactory: native,
    );
    expect(resolved, same(native));
  });

  test('DitMesh enables chat on every platform', () {
    expect(AppFeatures.fromEnvironment.chat, isTrue);
  });
}

final class _UnavailableBackend extends BackendFactory {
  _UnavailableBackend({this.error});

  final Object? error;
  bool prepared = false;

  @override
  String get label => 'Unavailable native backend';
  @override
  bool get isAvailable => false;
  @override
  Future<void> prepare() async {
    prepared = true;
    final error = this.error;
    if (error != null) throw error;
  }

  @override
  IdentityService createIdentityService() => throw UnimplementedError();
  @override
  ChatService createChatService(IdentityService identity) =>
      throw UnimplementedError();
}
