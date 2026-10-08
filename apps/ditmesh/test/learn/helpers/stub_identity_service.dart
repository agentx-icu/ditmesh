import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// The smallest [IdentityService] the Learn tab can run on: only
/// [dataDirectory] is real. Every other member throws [UnimplementedError]
/// through [noSuchMethod], which is exactly what the scope must tolerate.
final class StubIdentityService implements IdentityService {
  StubIdentityService(this.directory);

  final String directory;
  int dataDirectoryCalls = 0;

  @override
  Future<String> dataDirectory() async {
    dataDirectoryCalls++;
    return directory;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}
