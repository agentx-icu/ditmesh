import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../i18n/l10n_extension.dart';
import '../../training/qso_practice.dart';
import '../../training/training_controller.dart';
import '../common/app_bar_title.dart';
import '../stats/stats_screen.dart';
import '../appearance/appearance_page.dart';
import '../appearance/style_tokens.dart';
import '../appearance/ui_style.dart';
import 'learn_home_widgets.dart';
import 'learn_platform.dart';
import 'learn_playback.dart';
import 'conditions/conditions_playback.dart';
import 'materials/materials_screen.dart';
import 'placement/placement_offer_card.dart';
import 'placement/placement_screen.dart';
import 'plan/speed_advice_card.dart';
import 'qso/qso_setup_screen.dart';
import 'plan/today_plan_card.dart';
import 'receive/drill_picker_sheet.dart';
import 'receive/receive_drill_screen.dart';
import 'review/review_screen.dart';
import 'send/send_practice_screen.dart';
import 'settings/training_settings_screen.dart';
import 'telegraph/telegraph_practice_screen.dart';

/// Learn tab home: lesson state, daily goal, streak and the practice entry
/// points. One column on phones, two from [kLearnTwoColumnMinWidth].
class LearnHome extends StatelessWidget {
  const LearnHome({
    super.key,
    required this.controller,
    required this.playback,
    this.subtitle,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  /// Optional one-liner under the title (the shell's page description).
  final String? subtitle;

  Future<void> _push(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<Object?>(builder: (_) => screen));

  void _continueLesson(BuildContext context) => _push(
    context,
    ReceiveDrillScreen(
      controller: controller,
      playback: playback,
      session: controller.startLessonSession(),
    ),
  );

  Future<void> _receivePractice(BuildContext context) async {
    // The preview player lives only while the sheet is open.
    ConditionsPlayback? previewer;
    final picked = await showDrillPickerSheet(
      context,
      controller.availableReceiveKinds,
      onPreview: (preset) {
        final timing = controller.trainerSettings.toTiming();
        return (previewer ??= ConditionsPlayback(stopInBackground: true)).play(
          kConditionsPreviewText,
          RadioScenario.preset(
            preset,
            seed: 1,
            characterWpm: timing.wpm,
            effectiveWpm: timing.farnsworthWpm ?? timing.wpm,
            toneHz: controller.trainerSettings.toneHz,
          ),
        );
      },
    );
    await previewer?.dispose();
    if (picked == null || !context.mounted) {
      return;
    }
    final (kind, preset) = picked;
    await _push(
      context,
      ReceiveDrillScreen(
        controller: controller,
        playback: playback,
        session: controller.startReceiveSession(kind, preset: preset),
      ),
    );
  }

  void _sendPractice(BuildContext context) => _push(
    context,
    SendPracticeScreen(controller: controller, playback: playback),
  );

  void _review(BuildContext context) =>
      _push(context, ReviewScreen(controller: controller, playback: playback));

  void _settings(BuildContext context) => Navigator.of(context).push(
    TrainingSettingsScreen.route(controller: controller, playback: playback),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(s.navLearn),
        actions: <Widget>[
          IconButton(
            tooltip: s.appearanceTitle,
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => AppearancePage.open(context),
          ),
          IconButton(
            tooltip: s.learnStatistics,
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StatsScreen(
                  loadProgress: () async => controller.progress,
                  course: controller.course,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: s.learnSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _settings(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (!controller.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns =
                  constraints.maxWidth >= kLearnTwoColumnMinWidth;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child:
                        StyleTokens.of(context)?.style != null &&
                            StyleTokens.of(context)!.style != UiStyle.classic
                        ? _styledLayout(context, twoColumns)
                        : twoColumns
                        ? _twoColumn(context)
                        : _oneColumn(context),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (controller.loadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              context.s.learnLoadFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _status(BuildContext context) => Column(
    children: <Widget>[
      LessonCard(
        controller: controller,
        onContinue: () => _continueLesson(context),
      ),
      const SizedBox(height: 12),
      DailyGoalCard(controller: controller),
      ..._planCards(),
    ],
  );

  /// Today's plan and any pending speed advice, under the goal card.
  List<Widget> _planCards() => <Widget>[
    const SizedBox(height: 12),
    if (PlacementOfferCard.shows(controller))
      Builder(
        builder: (context) => PlacementOfferCard(
          controller: controller,
          onFromZero: () => _continueLesson(context),
          onCheckLevel: () => _push(
            context,
            PlacementScreen(controller: controller, playback: playback),
          ),
        ),
      ),
    SpeedAdviceCard(controller: controller),
    TodayPlanCard(controller: controller, playback: playback),
  ];

  Widget _actions(BuildContext context) => QuickActions(
    showContinue: false,
    dueCount: controller.dueChars.length,
    onContinueLesson: () => _continueLesson(context),
    onReceivePractice: () => _receivePractice(context),
    onSendPractice: () => _sendPractice(context),
    onReview: () => _review(context),
    onQso: _qsoAction(context),
    qsoFromLesson: TrainingController.qsoFromLesson,
    onMaterials: () => _materials(context),
    onTelegraph: () => _telegraph(context),
  );

  void _telegraph(BuildContext context) => _push(
    context,
    TelegraphPracticeScreen(controller: controller, playback: playback),
  );

  void _materials(BuildContext context) => _push(
    context,
    MaterialsScreen(controller: controller, playback: playback),
  );

  VoidCallback? _qsoAction(BuildContext context) => controller.qsoUnlocked
      ? () => _push(
          context,
          QsoSetupScreen(controller: controller, playback: playback),
        )
      : null;

  Widget _oneColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _header(context),
      _status(context),
      const SizedBox(height: 16),
      _actions(context),
    ],
  );

  Widget _twoColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _header(context),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: _status(context)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _actions(context)),
        ],
      ),
    ],
  );

  Widget _styledLayout(BuildContext context, bool twoColumns) {
    final lesson = LessonCard(
      controller: controller,
      onContinue: () => _continueLesson(context),
    );
    final actions = QuickActions(
      showContinue: false,
      dueCount: controller.dueChars.length,
      onContinueLesson: () => _continueLesson(context),
      onReceivePractice: () => _receivePractice(context),
      onSendPractice: () => _sendPractice(context),
      onReview: () => _review(context),
      onQso: _qsoAction(context),
      qsoFromLesson: TrainingController.qsoFromLesson,
      onMaterials: () => _materials(context),
      onTelegraph: () => _telegraph(context),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        if (twoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [lesson, const SizedBox(height: 12), actions],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    DailyGoalCard(controller: controller),
                    ..._planCards(),
                  ],
                ),
              ),
            ],
          )
        else ...[
          lesson,
          const SizedBox(height: 8),
          DailyGoalCard(controller: controller),
          ..._planCards(),
          const SizedBox(height: 12),
          actions,
        ],
      ],
    );
  }
}
