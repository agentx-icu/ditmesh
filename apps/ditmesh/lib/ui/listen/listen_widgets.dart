import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'listen_controller.dart';
import 'listen_settings.dart';

/// Signal meter plus tone indicator, rebuilt per audio chunk from
/// [ListenController.meter] without touching the rest of the screen.
class ListenLevelMeter extends StatelessWidget {
  const ListenLevelMeter({super.key, required this.meter});

  final ValueListenable<ListenMeter> meter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ListenMeter>(
      valueListenable: meter,
      builder: (context, m, _) => Row(
        children: <Widget>[
          const SizedBox(width: 4),
          Icon(
            Icons.mic,
            size: 20,
            color: m.hasSignal ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: context.s.listenLevel,
              value: '${(m.level * 100).round()}%',
              child: LinearProgressIndicator(
                value: m.level,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _ToneDot(on: m.toneOn),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ToneDot extends StatelessWidget {
  const _ToneDot({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final S s = context.s;
    return Semantics(
      label: s.listenToneOn,
      value: on ? s.listenStateOn : s.listenStateOff,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? scheme.primary : scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outline),
        ),
      ),
    );
  }
}

/// Detected frequency, lock badge and the manual tuning slider.
class ListenFrequencyPanel extends StatelessWidget {
  const ListenFrequencyPanel({super.key, required this.controller});

  final ListenController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final S s = context.s;
    final auto = controller.settings.autoTune;
    final String badge = !auto
        ? s.listenToneManual
        : controller.isToneLocked
        ? s.listenToneLocked
        : s.listenToneSearching;
    final hz = controller.frequencyHz.clamp(
      ListenSettings.minHz,
      ListenSettings.maxHz,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          dense: true,
          title: Text(s.listenTone),
          subtitle: Text(badge),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                s.listenHzValue(controller.frequencyHz.round()),
                style: theme.textTheme.titleMedium,
              ),
              if (!auto) ...<Widget>[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => controller.setAutoTune(true),
                  child: Text(s.listenRetune),
                ),
              ],
            ],
          ),
        ),
        Slider(
          value: hz,
          min: ListenSettings.minHz,
          max: ListenSettings.maxHz,
          divisions: ((ListenSettings.maxHz - ListenSettings.minHz) / 5)
              .round(),
          label: s.listenHzValue(hz.round()),
          onChanged: controller.setManualFrequency,
        ),
      ],
    );
  }
}

/// Live decoded text with auto-scroll and a copy button.
class ListenDecodedText extends StatelessWidget {
  const ListenDecodedText({
    super.key,
    required this.text,
    required this.isListening,
    required this.scrollController,
    required this.onCopy,
    this.textKey,
  });

  final String text;
  final bool isListening;
  final ScrollController scrollController;
  final VoidCallback? onCopy;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final S s = context.s;
    final mono = theme.textTheme.headlineSmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['Menlo', 'Consolas', 'Courier New'],
      height: 1.4,
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: <Widget>[
                Text(s.listenDecoded, style: theme.textTheme.labelLarge),
                const Spacer(),
                IconButton(
                  tooltip: s.listenCopy,
                  onPressed: text.isEmpty ? null : onCopy,
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SelectableText(text, key: textKey, style: mono),
                  ),
                ),
                if (text.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isListening ? s.listenEmptyHint : s.listenIdleHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pending pattern and speed estimate under the text.
class ListenStatsRow extends StatelessWidget {
  const ListenStatsRow({super.key, required this.controller});

  final ListenController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final S s = context.s;
    final pending = controller.pendingPattern;
    final wpm = controller.wpm;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: <Widget>[
          Text(s.listenPending, style: theme.textTheme.labelMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pending.isEmpty ? '—' : pending,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(s.listenSpeed, style: theme.textTheme.labelMedium),
          const SizedBox(width: 8),
          Text(
            wpm == null ? s.listenSpeedUnknown : s.listenWpmValue(wpm.round()),
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Permission / failure / background-stop banner.
class ListenStatusBanner extends StatelessWidget {
  const ListenStatusBanner({
    super.key,
    required this.controller,
    required this.onRetry,
  });

  final ListenController controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final S s = context.s;
    final String? message = switch (controller.status) {
      ListenStatus.failed => failureText(
        s,
        controller.failure?.kind ?? ListenFailureKind.startFailed,
      ),
      ListenStatus.starting => s.listenStarting,
      ListenStatus.idle when controller.stoppedInBackground =>
        s.listenStoppedInBackground,
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    final bool isError = controller.status == ListenStatus.failed;
    return MaterialBanner(
      backgroundColor: isError
          ? scheme.errorContainer
          : scheme.surfaceContainerHighest,
      content: Text(
        message,
        style: TextStyle(
          color: isError ? scheme.onErrorContainer : scheme.onSurface,
        ),
      ),
      leading: Icon(
        isError ? Icons.mic_off : Icons.info_outline,
        color: isError ? scheme.onErrorContainer : scheme.onSurface,
      ),
      actions: <Widget>[
        if (isError)
          TextButton(onPressed: onRetry, child: Text(s.listenPermissionRetry))
        else
          const SizedBox.shrink(),
      ],
    );
  }

  /// The localised message for [kind]. The platform's error detail is
  /// diagnostics only and deliberately not a parameter here.
  @visibleForTesting
  static String failureText(S s, ListenFailureKind kind) => switch (kind) {
    ListenFailureKind.permissionDenied => s.listenPermissionDenied,
    ListenFailureKind.noInputDevice => s.listenNoInput,
    ListenFailureKind.startFailed => s.listenStartFailed,
    ListenFailureKind.streamFailed => s.listenStreamFailed,
  };
}
