import 'dart:convert';
import 'dart:io';

import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh/training/training_settings_store.dart';

/// Runs in the Dart VM without assertions, as a production codec check.
Future<void> main(List<String> args) async {
  final values = <String, Object?>{};
  for (final file in Directory(args.single).listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final name = file.uri.pathSegments.last;
    values[name] = name.startsWith('progress')
        ? (await FileTrainerStore(file).load())?.currentLesson
        : (await FileTrainingSettingsStore(file).load())?.trainer.toneHz;
  }
  stdout.write(jsonEncode(values));
}
