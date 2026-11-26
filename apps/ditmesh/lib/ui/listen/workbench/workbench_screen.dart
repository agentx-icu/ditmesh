import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart' show UnsupportedDataVersion;
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/audio_material_store.dart';
import '../../../training/guest_profile.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_controller_host.dart';
import '../../account/account_widgets.dart';
import '../../common/app_bar_title.dart';
import '../../learn/learning_unavailable.dart';
import 'recording_files.dart';
import 'workbench_controller.dart';
import 'workbench_decode_panel.dart';
import 'workbench_library_sheet.dart';
import 'workbench_waveform.dart';

part 'workbench_recording_view.dart';

/// Creates an owned player for a workbench opened on the root navigator.
/// Without an injected factory the workbench uses the native player.
abstract interface class WorkbenchPlayerFactory {
  ClipPlayer create();
}

/// Recorded-audio copying workbench (functional spec §11): import a WAV
/// recording, select and loop a part, decode it or copy it yourself, and
/// keep selections as local audio materials. Imports need no microphone
/// permission; nothing is ever sent anywhere.
class WorkbenchScreen extends StatefulWidget {
  const WorkbenchScreen({
    super.key,
    this.picker,
    this.player,
    this.profileRoot,
    this.training,
  });

  /// Injected in tests; defaults to the platform file picker.
  final RecordingPicker? picker;

  /// Injected in tests; defaults to SoLoud.
  final ClipPlayer? player;

  /// The learning profile's media root ([RecordingLibrary.root]);
  /// defaults to the identity's root, or the guest directory.
  final Future<String> Function()? profileRoot;

  /// The shared training controller; defaults to the app's host.
  final Future<TrainingController> Function()? training;

  @override
  State<WorkbenchScreen> createState() => _WorkbenchScreenState();
}

/// The learning profile's media root: the identity's root, or the guest
/// directory when learning without an identity.
Future<String> _profileDirectory(BuildContext context) {
  final identity = context.read<IdentityService>();
  GuestStore? guest;
  try {
    guest = context.read<GuestStore?>();
  } on ProviderNotFoundException {
    guest = null;
  }
  if (identity.current == null && guest != null) return guest.directory();
  // The identity root: media stay out of the backed-up data directory.
  return identity.dataDirectory().then(p.dirname);
}

class _WorkbenchScreenState extends State<WorkbenchScreen>
    with WidgetsBindingObserver {
  WorkbenchController? _c;
  TrainingController? _training;
  late final WorkbenchPlayerFactory? _playerFactory;
  late final ClipPlayer _player =
      widget.player ?? _playerFactory?.create() ?? SoloudClipPlayer();
  bool _unavailable = false;
  bool _visible = true;
  bool _picking = false;
  bool _saving = false;
  Future<List<(AudioMaterial, bool)>>? _clips;
  bool get _mediaBusy => _picking || _saving || (_c?.busy ?? false);
  Object? _unavailableError;

  @override
  void initState() {
    super.initState();
    // Keep the player lazy, but never look up ancestors from dispose when a
    // route closes while its asynchronous profile setup is still pending.
    _playerFactory = widget.player == null
        ? context.read<WorkbenchPlayerFactory?>()
        : null;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setup());
  }

  Future<void> _setup() async {
    if (_unavailable) {
      setState(() {
        _unavailable = false;
        _unavailableError = null;
      });
    }
    final WorkbenchController controller;
    try {
      final dir =
          await (widget.profileRoot ?? () => _profileDirectory(context))();
      if (!mounted) return;
      controller = WorkbenchController(
        library: RecordingLibrary(dir),
        player: _player,
        onIoError: _showIoFailure,
      )..addListener(_changed);
      // A retry replaces the controller of the failed attempt (the player
      // is the screen's and stays).
      final previous = _c;
      setState(() => _c = controller);
      previous
        ?..removeListener(_changed)
        ..dispose();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _unavailable = true;
          _unavailableError = error;
        });
      }
      return;
    }
    final TrainingController training;
    try {
      training = await (widget.training ?? _hostController)();
    } on Object catch (error) {
      // Chat builds without an identity: attempts are scored, not recorded.
      // The offline build always has its profile, so a failure is a storage
      // problem: say so and offer a retry.
      if (mounted &&
          (error is UnsupportedDataVersion ||
              learningRetryable(context, error))) {
        setState(() {
          _unavailable = true;
          _unavailableError = error;
        });
      }
      return;
    }
    // A recovered or partially readable index can omit existing recordings.
    // Opening the workbench must leave their WAV files available to recover.
    if (mounted && identical(_c, controller)) {
      setState(() {
        _training = training;
        _updateClips();
      });
    }
  }

  Future<TrainingController> _hostController() {
    final host = context.read<TrainingControllerHost?>();
    if (host == null) throw StateError('no training host');
    return host.controller();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    if (!_visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_visible) unawaited(_c?.stopPlayback());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop on background; playing again is the learner's choice.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_c?.stopPlayback());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _import() async {
    final c = _c;
    if (c == null || _mediaBusy || _unavailable) return;
    final picker =
        widget.picker ??
        PlatformRecordingPicker(dialogTitle: context.s.workbenchImport);
    setState(() => _picking = true);
    final PickedRecording? picked;
    try {
      picked = await picker.pick();
    } on Object {
      _showIoFailure();
      return;
    } finally {
      if (mounted) setState(() => _picking = false);
    }
    if (picked == null || !mounted) return;
    final ok = await c.importRecording(picked);
    if (!ok && mounted) _showFailure(c);
  }

  void _showFailure(WorkbenchController c) {
    if (mounted) _showError(failureText(context.s, c));
  }

  void _showIoFailure() {
    if (mounted) _showError(context.s.workbenchErrorIo);
  }

  void _showError(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final c = _c;
    final training = _training;
    final info = c?.info;
    if (c == null || training == null || info == null || _mediaBusy) return;
    final s = context.s;
    final name = c.name ?? '';
    final start = info.durationOf(c.start);
    final end = info.durationOf(c.end);
    var file = c.file;
    setState(() => _saving = true);
    try {
      final entry = await showSaveSelectionDialog(context, name);
      if (entry == null || !mounted) return;
      final id = training.newAudioMaterialId();
      if (file == RecordingLibrary.workingFile) {
        file = 'media/recordings/$id.wav';
        await c.library.keepWorkingAs(file);
      }
      await training.upsertAudioMaterial(
        AudioMaterial(
          id: id,
          title: entry.$1,
          note: entry.$2,
          file: file,
          originalName: name,
          start: start,
          end: end,
          sampleRate: info.sampleRate,
          channels: info.channels,
          createdAt: training.now(),
        ),
      );
      if (mounted) {
        setState(_updateClips);
        _showError(s.workbenchSaved);
      }
    } on Object {
      if (mounted) _showError(s.workbenchSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _library() async {
    final c = _c;
    final training = _training;
    if (c == null || training == null || _mediaBusy) return;
    await showWorkbenchLibrary(
      context,
      controller: c,
      training: training,
      picker: widget.picker,
      onFailure: () => _showFailure(c),
      onChanged: () {
        if (mounted) setState(_updateClips);
      },
    );
  }

  void _updateClips() {
    final training = _training;
    final c = _c;
    if (training == null || c == null) return;
    _clips = _listRecentClips(training, c.library)..ignore();
  }

  Future<List<(AudioMaterial, bool)>> _listRecentClips(
    TrainingController training,
    RecordingLibrary library,
  ) async {
    final clips = await training.loadAudioMaterials();
    return [
      for (final clip in clips.take(3)) (clip, await library.exists(clip.file)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = _c;
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(s.workbenchTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.workbenchLibrary,
            onPressed: _training == null || c == null || _mediaBusy
                ? null
                : _library,
            icon: const Icon(Icons.library_music_outlined),
          ),
          IconButton(
            key: const ValueKey('workbench-import'),
            tooltip: s.workbenchImport,
            onPressed: c == null || _mediaBusy || _unavailable ? null : _import,
            icon: const Icon(Icons.file_open_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _unavailable
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        learningUnavailableText(context, _unavailableError),
                        textAlign: TextAlign.center,
                      ),
                      if (learningRetryable(context, _unavailableError)) ...[
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          key: const ValueKey('workbench-retry'),
                          onPressed: () => unawaited(_setup()),
                          child: Text(s.actionRetry),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : c == null
            ? const Center(child: CircularProgressIndicator())
            : AccountPageBody(
                maxWidth: 820,
                aside: [
                  if (_training != null)
                    AccountPanel(
                      children: [
                        Text(
                          s.workbenchLibrary,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        FutureBuilder<List<(AudioMaterial, bool)>>(
                          future: _clips,
                          builder: (context, snapshot) {
                            final recent = snapshot.data;
                            if (snapshot.hasError) {
                              return Text(s.workbenchErrorIo);
                            }
                            if (recent == null) return const SizedBox.shrink();
                            if (recent.isEmpty) {
                              return Text(s.workbenchLibraryEmpty);
                            }
                            return Column(
                              children: [
                                for (final (clip, available) in recent)
                                  ListTile(
                                    key: ValueKey(
                                      'workbench-preview-${clip.id}',
                                    ),
                                    leading: Icon(
                                      available
                                          ? Icons.headphones
                                          : Icons.error_outline,
                                    ),
                                    title: Text(clip.title),
                                    subtitle: Text(
                                      available
                                          ? formatClock(clip.end - clip.start)
                                          : s.workbenchMissing,
                                    ),
                                    onTap: _mediaBusy ? null : _library,
                                  ),
                              ],
                            );
                          },
                        ),
                        TextButton(
                          onPressed: _mediaBusy ? null : _library,
                          child: Text(s.workbenchLibrary),
                        ),
                      ],
                    ),
                ],
                children: [
                  AccountPanel(
                    children: [
                      if (c.info == null) _empty(context, c) else _loaded(c),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Localised reason an import or open failed.
String failureText(S s, WorkbenchController c) => switch (c.failure) {
  WorkbenchFailure.missingFile => s.workbenchErrorMissing,
  WorkbenchFailure.io || null => s.workbenchErrorIo,
  WorkbenchFailure.format => workbenchWavError(s, c.wavError),
};
