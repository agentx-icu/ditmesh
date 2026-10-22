import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'second process activates owner; crash releases ownership',
    () async {
      final dir = await Directory.systemTemp.createTemp('desktop_instance_');
      final script = File(
        'test/desktop/helpers/desktop_instance_probe.dart',
      ).absolute.path;
      final processes = <Process>[];
      Future<Process> launch() async {
        final process = await Process.start('dart', [script, dir.path]);
        processes.add(process);
        return process;
      }

      try {
        final first = await launch();
        final firstLines = StreamIterator(
          first.stdout.transform(utf8.decoder).transform(const LineSplitter()),
        );
        expect(
          await firstLines.moveNext().timeout(const Duration(seconds: 10)),
          isTrue,
        );
        expect(firstLines.current, 'owner');
        final second = await launch();
        expect(
          await second.stdout.transform(utf8.decoder).join(),
          'secondary\n',
        );
        expect(await second.exitCode, 0);
        expect(
          await firstLines.moveNext().timeout(const Duration(seconds: 5)),
          isTrue,
        );
        expect(firstLines.current, 'activated');
        first.kill(ProcessSignal.sigkill);
        await first.exitCode;
        await firstLines.cancel();
        final third = await launch();
        final thirdLines = StreamIterator(
          third.stdout.transform(utf8.decoder).transform(const LineSplitter()),
        );
        expect(
          await thirdLines.moveNext().timeout(const Duration(seconds: 10)),
          isTrue,
        );
        expect(thirdLines.current, 'owner');
        third.stdin.writeln('close');
        expect(await third.exitCode, 0);
        await thirdLines.cancel();
      } finally {
        for (final process in processes) {
          process.kill(ProcessSignal.sigkill);
          await process.exitCode;
        }
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );
}
