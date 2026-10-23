import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Fixed origins only: never substitute a notification payload or SDK message.
enum DiagnosticEvent {
  framework,
  unhandledAsync,
  notificationShow,
  notificationCancel,
  notificationOther,
}

/// Console diagnostics only; no files, uploads, identifiers or error values.
///
/// Release hooks deliberately omit supplied stacks and Flutter diagnostic
/// context: either can contain arbitrary application data. Native crash capture
/// and exact-build symbolication remain separate release-readiness work.
final class ApplicationDiagnostics {
  ApplicationDiagnostics({
    this.debugMode = kDebugMode,
    void Function(String)? write,
  }) : _write = write;

  final bool debugMode;
  final void Function(String)? _write;

  void _emit(String message) => (_write ?? debugPrint)(message);

  /// Lazy so release builds never stringify raw exceptions or platform data.
  void debug(String Function() message) {
    if (debugMode) _emit(message());
  }

  void report(DiagnosticEvent event, Object error) {
    // An error's toString/runtimeType, even a custom StackTrace, is untrusted.
    final type = switch (error) {
      PlatformException() => 'PlatformException',
      MissingPluginException() => 'MissingPluginException',
      FileSystemException() => 'FileSystemException',
      TimeoutException() => 'TimeoutException',
      FormatException() => 'FormatException',
      StateError() => 'StateError',
      ArgumentError() => 'ArgumentError',
      UnsupportedError() => 'UnsupportedError',
      _ => 'Object',
    };
    _emit('[DitMesh] ${event.name}: $type');
  }

  /// Install before binding/startup, without creating a different Dart zone.
  void installErrorHandlers() {
    final previousFlutter = FlutterError.onError;
    final previousDispatcher = PlatformDispatcher.instance.onError;
    FlutterError.onError = (details) {
      if (debugMode) {
        previousFlutter?.call(details);
      } else {
        report(DiagnosticEvent.framework, details.exception);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (debugMode) return previousDispatcher?.call(error, stack) ?? false;
      report(DiagnosticEvent.unhandledAsync, error);
      // Handled here; the runtime's fallback would print the raw exception.
      return true;
    };
  }
}

final applicationDiagnostics = ApplicationDiagnostics();

void debugLog(String Function() message) =>
    applicationDiagnostics.debug(message);
