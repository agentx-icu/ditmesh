import 'package:ditmesh/diagnostics/application_diagnostics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _PrivateError {
  @override
  String toString() => throw StateError('PRIVATE_ERROR_WAS_READ');
}

void main() {
  test('the default writer honors the current debugPrint adapter', () {
    final previous = debugPrint;
    addTearDown(() => debugPrint = previous);
    final first = <String?>[];
    final second = <String?>[];
    debugPrint = (message, {wrapWidth}) => first.add(message);
    final diagnostics = ApplicationDiagnostics(debugMode: true);
    debugPrint = (message, {wrapWidth}) => second.add(message);
    diagnostics.debug(() => 'developer diagnostic');
    expect(first, isEmpty);
    expect(second, ['developer diagnostic']);
  });
  test('release never evaluates a raw diagnostic callback', () {
    final output = <String>[];
    final diagnostics = ApplicationDiagnostics(
      debugMode: false,
      write: output.add,
    );
    diagnostics.debug(() => throw StateError('PRIVATE_LAZY_MARKER'));
    expect(output, isEmpty);
  });

  test('debug retains developer diagnostics', () {
    final output = <String>[];
    ApplicationDiagnostics(
      debugMode: true,
      write: output.add,
    ).debug(() => 'debug detail');
    expect(output, ['debug detail']);
  });

  test('a failing diagnostic writer never escapes an error hook', () {
    final previousFlutter = FlutterError.onError;
    final previousDispatcher = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousDispatcher;
    });
    var attempts = 0;
    ApplicationDiagnostics(
      debugMode: false,
      write: (_) {
        attempts++;
        throw StateError('PRIVATE_WRITER_FAILURE');
      },
    ).installErrorHandlers();
    expect(
      () => FlutterError.onError!(
        FlutterErrorDetails(exception: _PrivateError()),
      ),
      returnsNormally,
    );
    expect(
      PlatformDispatcher.instance.onError!(_PrivateError(), StackTrace.current),
      isTrue,
    );
    expect(attempts, 2, reason: 'no recursive logging fallback');
  });

  test(
    'safe records contain only a fixed event and allowlisted error type',
    () {
      final output = <String>[];
      final diagnostics = ApplicationDiagnostics(
        debugMode: false,
        write: output.add,
      );
      diagnostics.report(
        DiagnosticEvent.notificationShow,
        PlatformException(
          code: 'PRIVATE_CODE',
          message: 'PRIVATE_MESSAGE',
          details: 'PRIVATE_DETAILS',
        ),
      );
      diagnostics.report(DiagnosticEvent.notificationCancel, _PrivateError());
      expect(output, [
        '[DitMesh] notificationShow: PlatformException',
        '[DitMesh] notificationCancel: Object',
      ]);
    },
  );

  test('release hooks never render exception, context or supplied stack', () {
    final previousFlutter = FlutterError.onError;
    final previousDispatcher = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousDispatcher;
    });
    final output = <String>[];
    ApplicationDiagnostics(
      debugMode: false,
      write: output.add,
    ).installErrorHandlers();
    FlutterError.onError!(
      FlutterErrorDetails(
        exception: _PrivateError(),
        stack: StackTrace.fromString('PRIVATE_STACK'),
        context: ErrorDescription('PRIVATE_CONTEXT'),
        informationCollector: () => [ErrorDescription('PRIVATE_INFORMATION')],
      ),
    );
    expect(
      PlatformDispatcher.instance.onError!(
        StateError('PRIVATE_ASYNC'),
        StackTrace.fromString('PRIVATE_ASYNC_STACK'),
      ),
      isTrue,
    );
    expect(output, [
      '[DitMesh] framework: Object',
      '[DitMesh] unhandledAsync: StateError',
    ]);
  });

  test('debug hooks preserve previous handlers and dispatcher result', () {
    final previousFlutter = FlutterError.onError;
    final previousDispatcher = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = previousFlutter;
      PlatformDispatcher.instance.onError = previousDispatcher;
    });
    var frameworkCalls = 0;
    var dispatcherCalls = 0;
    FlutterError.onError = (_) => frameworkCalls++;
    PlatformDispatcher.instance.onError = (_, _) {
      dispatcherCalls++;
      return false;
    };
    final output = <String>[];
    ApplicationDiagnostics(
      debugMode: true,
      write: output.add,
    ).installErrorHandlers();
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('debug')));
    expect(
      PlatformDispatcher.instance.onError!(
        StateError('debug'),
        StackTrace.current,
      ),
      isFalse,
    );
    expect(frameworkCalls, 1);
    expect(dispatcherCalls, 1);
    expect(output, isEmpty);
  });
}
