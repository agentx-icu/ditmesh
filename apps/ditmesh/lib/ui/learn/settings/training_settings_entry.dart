import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_controller_host.dart';
import '../../common/app_bar_title.dart';
import '../learn_playback.dart';
import '../learning_unavailable.dart';
import 'training_settings_screen.dart';

/// Named-route target for `/settings/training` (pushed from the Me page).
/// Resolves the shared [TrainingController] through
/// [TrainingControllerHost.fromContext] so the settings page edits the same
/// instance the Learn tab uses.
class TrainingSettingsEntry extends StatefulWidget {
  const TrainingSettingsEntry({
    super.key,
    this.playback = const DevicePlaybackFactory(),
  });

  final LearnPlaybackFactory playback;

  @override
  State<TrainingSettingsEntry> createState() => _TrainingSettingsEntryState();
}

class _TrainingSettingsEntryState extends State<TrainingSettingsEntry> {
  late Future<TrainingController> _controller =
      TrainingControllerHost.fromContext(context);

  void _retry() =>
      setState(() => _controller = TrainingControllerHost.fromContext(context));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrainingController>(
      future: _controller,
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (controller != null) {
          return TrainingSettingsScreen(
            controller: controller,
            playback: widget.playback,
          );
        }
        return Scaffold(
          appBar: AppBar(title: AppBarTitle(context.s.learnSettings)),
          body: Center(
            child: snapshot.hasError
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          learningUnavailableText(context),
                          textAlign: TextAlign.center,
                        ),
                        if (learningRetryable(context)) ...[
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            key: const ValueKey('training-settings-retry'),
                            onPressed: _retry,
                            child: Text(context.s.actionRetry),
                          ),
                        ],
                      ],
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
