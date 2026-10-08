import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/guest_profile.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_settings_store.dart';

/// Guest storage without file I/O, for widget tests.
final class MemoryGuestStore extends GuestStore {
  MemoryGuestStore() : super(root: () async => '/memory/guest');

  bool active = false;
  bool progress = false;
  int controllersOpened = 0;
  final InMemoryTrainerStore trainer = InMemoryTrainerStore();

  @override
  Future<String> directory() async => '/memory/guest';

  @override
  Future<bool> isActive() async => active;

  @override
  Future<void> setActive(bool value) async => active = value;

  @override
  Future<bool> hasProgress() async => progress;

  @override
  Future<void> clear() async => progress = false;

  @override
  Future<TrainingController> openController() async {
    controllersOpened++;
    final c = TrainingController(
      progressStore: trainer,
      settingsStore: InMemoryTrainingSettingsStore(),
      profileKey: GuestProfile.profileKey,
    );
    await c.load();
    return c;
  }
}
