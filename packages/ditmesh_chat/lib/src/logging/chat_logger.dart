import 'package:tim2tox_dart/interfaces/logger_service.dart';

/// Severity of a [ChatLogRecord].
enum ChatLogLevel { debug, info, warning, error }

/// One log line produced by the chat backend (or by Tim2Tox through the
/// [LoggerService] adapter).
class ChatLogRecord {
  const ChatLogRecord({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final ChatLogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final tag = level.name.toUpperCase();
    final err = error == null ? '' : ' | $error';
    return '[$tag] $message$err';
  }
}

/// Logging seam for the whole package.
///
/// The app decides where lines go (its own logger, a file, stderr): pass a
/// [ChatLogger] to `DitmeshChatBackend`. Everything inside this package and
/// everything Tim2Tox logs through its `LoggerService` flows into one sink.
abstract interface class ChatLogger {
  void log(ChatLogRecord record);
}

/// Convenience methods shared by the package internals.
extension ChatLoggerX on ChatLogger {
  void debug(String message) =>
      log(ChatLogRecord(level: ChatLogLevel.debug, message: message));

  void info(String message) =>
      log(ChatLogRecord(level: ChatLogLevel.info, message: message));

  void warn(String message) =>
      log(ChatLogRecord(level: ChatLogLevel.warning, message: message));

  void error(String message, [Object? error, StackTrace? stackTrace]) => log(
        ChatLogRecord(
          level: ChatLogLevel.error,
          message: message,
          error: error,
          stackTrace: stackTrace,
        ),
      );
}

/// Drops everything. Used when the host passes no logger.
class SilentChatLogger implements ChatLogger {
  const SilentChatLogger();

  @override
  void log(ChatLogRecord record) {}
}

/// Forwards each record to a callback — the simplest way for an app to route
/// backend logs into its own logging pipeline.
class CallbackChatLogger implements ChatLogger {
  const CallbackChatLogger(this.onRecord);

  final void Function(ChatLogRecord record) onRecord;

  @override
  void log(ChatLogRecord record) => onRecord(record);
}

/// Keeps records in memory; for tests and diagnostics screens.
class MemoryChatLogger implements ChatLogger {
  final List<ChatLogRecord> records = <ChatLogRecord>[];

  @override
  void log(ChatLogRecord record) => records.add(record);
}

/// Adapts a [ChatLogger] to Tim2Tox's [LoggerService] host interface.
class Tim2ToxLoggerAdapter implements LoggerService {
  const Tim2ToxLoggerAdapter(this._logger);

  final ChatLogger _logger;

  @override
  void log(String message) => _logger.info(message);

  @override
  void logDebug(String message) => _logger.debug(message);

  @override
  void logWarning(String message) => _logger.warn(message);

  @override
  void logError(String message, Object error, StackTrace stack) =>
      _logger.error(message, error, stack);
}
