import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/logging/chat_logger.dart';

void main() {
  group('ChatLogRecord', () {
    test('renders the level tag and the message', () {
      const record = ChatLogRecord(level: ChatLogLevel.info, message: 'hello');
      expect(record.toString(), '[INFO] hello');
    });

    test('appends the error when there is one', () {
      final record = ChatLogRecord(
        level: ChatLogLevel.error,
        message: 'boom',
        error: StateError('bad'),
        stackTrace: StackTrace.current,
      );
      expect(record.toString(), '[ERROR] boom | Bad state: bad');
    });
  });

  group('ChatLoggerX', () {
    test('each convenience method stamps its level', () {
      final logger = MemoryChatLogger();
      logger
        ..debug('d')
        ..info('i')
        ..warn('w')
        ..error('e');
      expect(
        logger.records.map((r) => r.level),
        [
          ChatLogLevel.debug,
          ChatLogLevel.info,
          ChatLogLevel.warning,
          ChatLogLevel.error,
        ],
      );
      expect(logger.records.map((r) => r.message), ['d', 'i', 'w', 'e']);
      expect(logger.records.every((r) => r.error == null), isTrue);
    });

    test('error carries the thrown object and its stack', () {
      final logger = MemoryChatLogger();
      final err = ArgumentError('x');
      final st = StackTrace.current;
      logger.error('failed', err, st);
      final record = logger.records.single;
      expect(record.error, same(err));
      expect(record.stackTrace, same(st));
    });
  });

  test('SilentChatLogger drops everything', () {
    const logger = SilentChatLogger();
    expect(() => logger.info('ignored'), returnsNormally);
  });

  test('CallbackChatLogger forwards each record', () {
    final seen = <ChatLogRecord>[];
    final logger = CallbackChatLogger(seen.add);
    logger.warn('careful');
    expect(seen.single.level, ChatLogLevel.warning);
    expect(seen.single.message, 'careful');
  });

  test('Tim2ToxLoggerAdapter maps the host interface onto the levels', () {
    final logger = MemoryChatLogger();
    final adapter = Tim2ToxLoggerAdapter(logger);
    final err = StateError('native');
    final st = StackTrace.current;
    adapter
      ..log('plain')
      ..logDebug('dbg')
      ..logWarning('warn')
      ..logError('err', err, st);
    expect(
      logger.records.map((r) => (r.level, r.message)),
      [
        (ChatLogLevel.info, 'plain'),
        (ChatLogLevel.debug, 'dbg'),
        (ChatLogLevel.warning, 'warn'),
        (ChatLogLevel.error, 'err'),
      ],
    );
    expect(logger.records.last.error, same(err));
    expect(logger.records.last.stackTrace, same(st));
  });
}
