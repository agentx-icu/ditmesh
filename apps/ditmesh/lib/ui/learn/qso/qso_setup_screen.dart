import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/qso_practice.dart';
import '../../../training/training_controller.dart';
import '../learn_playback.dart';
import 'qso_screen.dart';

/// Configure a simulated QSO: scenario and the learner's own callsign,
/// name and QTH (controlled single words). Offers to resume an unfinished
/// QSO. Everything runs locally; nothing goes on the wire.
class QsoSetupScreen extends StatefulWidget {
  const QsoSetupScreen({
    super.key,
    required this.controller,
    required this.playback,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  @override
  State<QsoSetupScreen> createState() => _QsoSetupScreenState();
}

class _QsoSetupScreenState extends State<QsoSetupScreen> {
  final _call = TextEditingController();
  final _name = TextEditingController();
  final _qth = TextEditingController();
  QsoScenario _scenario = QsoScenario.respondToCq;
  QsoDraft? _draft;
  bool _loaded = false;

  TrainingController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final station =
        await _c.loadQsoStation() ??
        QsoStation.random(Random(_c.random.nextInt(1 << 30)));
    await _c.recoverFinishedQso();
    final loaded = await _c.loadQsoDraft();
    // Older drafts may hold a finished QSO: commit it, never resume it.
    final draft = loaded != null && loaded.session.isDone ? null : loaded;
    if (loaded != null && loaded.session.isDone) {
      await _c.finishQso(loaded.session, loaded.active);
    }
    if (!mounted) return;
    setState(() {
      _call.text = station.callsign;
      _name.text = station.name;
      _qth.text = station.qth;
      _draft = draft;
      _loaded = true;
    });
  }

  String? _callError(S s) =>
      QsoStation.isValidCallsign(_call.text) ? null : s.learnQsoInvalidCall;

  String? _wordError(S s, TextEditingController c) =>
      QsoStation.isValidWord(c.text) ? null : s.learnQsoInvalidWord;

  bool get _valid =>
      QsoStation.isValidCallsign(_call.text) &&
      QsoStation.isValidWord(_name.text) &&
      QsoStation.isValidWord(_qth.text);

  Future<void> _open(QsoSession session, {QsoDraft? resumed}) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QsoScreen(
          controller: _c,
          playback: widget.playback,
          session: session,
          resumed: resumed,
        ),
      ),
    );
  }

  Future<void> _start() async {
    final station = QsoStation(
      callsign: _call.text,
      name: _name.text,
      qth: _qth.text,
    ).normalized();
    final t = _c.trainerSettings;
    try {
      await _c.saveQsoStation(station);
      await _c.discardQsoDraft();
    } on Object {
      // The QSO still runs; the station is asked again next time.
    }
    if (!mounted) return;
    await _open(
      QsoSession.start(
        scenario: _scenario,
        seed: _c.random.nextInt(1 << 30),
        local: station,
        characterWpm: t.characterWpm,
        effectiveWpm: t.isFarnsworth ? t.farnsworthWpm! : t.characterWpm,
      ),
    );
  }

  @override
  void dispose() {
    _call.dispose();
    _name.dispose();
    _qth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.learnQsoTitle)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_draft != null) ...<Widget>[
                          FilledButton.tonalIcon(
                            key: const ValueKey('qso-resume'),
                            onPressed: () =>
                                _open(_draft!.session, resumed: _draft),
                            icon: const Icon(Icons.restore),
                            label: Text(s.learnQsoResume),
                          ),
                          const SizedBox(height: 16),
                        ],
                        RadioGroup<QsoScenario>(
                          groupValue: _scenario,
                          onChanged: (v) => setState(() => _scenario = v!),
                          child: Column(
                            children: <Widget>[
                              RadioListTile<QsoScenario>(
                                value: QsoScenario.respondToCq,
                                title: Text(s.learnQsoRespond),
                                subtitle: Text(s.learnQsoRespondHint),
                              ),
                              RadioListTile<QsoScenario>(
                                value: QsoScenario.callCq,
                                title: Text(s.learnQsoCall),
                                subtitle: Text(s.learnQsoCallHint),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _call,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: s.learnQsoYourCall,
                            errorText: _callError(s),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: s.learnQsoYourName,
                            errorText: _wordError(s, _name),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _qth,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: s.learnQsoYourQth,
                            errorText: _wordError(s, _qth),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.learnQsoOffline,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const ValueKey('qso-start'),
                          onPressed: _valid ? _start : null,
                          icon: const Icon(Icons.cell_tower),
                          label: Text(s.learnQsoStart),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
