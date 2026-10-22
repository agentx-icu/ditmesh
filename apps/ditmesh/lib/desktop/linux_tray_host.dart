import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A registered AppIndicator is not proof that the desktop displays it.
/// Query the live StatusNotifier host instead of guessing from desktop names.
Future<bool> linuxTrayHostAvailable() async {
  Process? process;
  try {
    process = await Process.start('gdbus', [
      'call',
      '--session',
      '--dest',
      'org.kde.StatusNotifierWatcher',
      '--object-path',
      '/StatusNotifierWatcher',
      '--method',
      'org.freedesktop.DBus.Properties.Get',
      'org.kde.StatusNotifierWatcher',
      'IsStatusNotifierHostRegistered',
    ]);
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.drain<void>();
    final code = await process.exitCode.timeout(const Duration(seconds: 2));
    final result = await output;
    await errors;
    return code == 0 && RegExp(r'<true>').hasMatch(result);
  } on Object {
    return false;
  } finally {
    process?.kill();
  }
}
