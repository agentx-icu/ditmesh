import 'dart:io';

import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_doc_store.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';

void main() {
  for (final name in ['audio_materials', 'group_practice']) {
    test('future $name primary and backup block writes', () async {
      final dir = await Directory.systemTemp.createTemp('future_doc_');
      try {
        final docs = FileTrainingDocStore.inDataDirectory(dir.path);
        final file = File('${docs.directory.path}/$name.json');
        await file.parent.create(recursive: true);
        const future = '{"v":99,"futureField":"keep"}';
        await file.writeAsString(future);
        await expectLater(
          docs.read(name),
          throwsA(isA<UnsupportedDataVersion>()),
        );
        await expectLater(
          docs.write(name, {'v': 1}),
          throwsA(isA<UnsupportedDataVersion>()),
        );
        expect(await file.readAsString(), future);
        await file.writeAsString('{"v":1}');
        final backup = File('${file.path}.bak');
        await backup.writeAsString(future);
        await expectLater(
          docs.write(name, {'v': 1}),
          throwsA(isA<UnsupportedDataVersion>()),
        );
        expect(await backup.readAsString(), future);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  }
  for (final document in ['progress', 'settings']) {
    test(
      'future $document backup is preserved beside a current primary',
      () async {
        final dir = await Directory.systemTemp.createTemp('future_backup_');
        try {
          final file = File('${dir.path}/training/$document.json');
          await file.parent.create(recursive: true);
          const current = '{"version":1}';
          const future = '{"version":99,"futureField":"keep"}';
          await file.writeAsString(current);
          final backup = File('${file.path}.bak');
          await backup.writeAsString(future);
          final save = document == 'progress'
              ? FileTrainerStore.inDataDirectory(
                  dir.path,
                ).save(TrainerProgress())
              : FileTrainingSettingsStore.inDataDirectory(
                  dir.path,
                ).save(TrainingSettings.defaults);
          await expectLater(save, throwsA(isA<UnsupportedDataVersion>()));
          expect(await file.readAsString(), current);
          expect(await backup.readAsString(), future);
        } finally {
          await dir.delete(recursive: true);
        }
      },
    );
    test(
      'future $document blocks controller and keeps original plus backup',
      () async {
        final dir = await Directory.systemTemp.createTemp('future_training_');
        final progress = FileTrainerStore.inDataDirectory(dir.path);
        final settings = FileTrainingSettingsStore.inDataDirectory(dir.path);
        final controller = TrainingController(
          progressStore: progress,
          settingsStore: settings,
        );
        try {
          final file = File('${dir.path}/training/$document.json');
          await file.parent.create(recursive: true);
          const future = '{"version":99,"futureField":"keep"}';
          await file.writeAsString(future);
          final backup = File('${file.path}.bak');
          await backup.writeAsString('{"version":1}');
          await expectLater(
            controller.load(),
            throwsA(isA<UnsupportedDataVersion>()),
          );
          if (document == 'progress') {
            await expectLater(
              progress.save(TrainerProgress()),
              throwsA(isA<UnsupportedDataVersion>()),
            );
          } else {
            await expectLater(
              settings.save(TrainingSettings.defaults),
              throwsA(isA<UnsupportedDataVersion>()),
            );
          }
          expect(await file.readAsString(), future);
          expect(await backup.readAsString(), '{"version":1}');
          expect(await File('${file.path}.corrupt').exists(), isFalse);
        } finally {
          controller.dispose();
          await dir.delete(recursive: true);
        }
      },
    );
  }
}
