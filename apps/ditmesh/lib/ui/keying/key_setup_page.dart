import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morse_io/morse_io.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../keying/key_profile.dart';
import '../../keying/key_profiles.dart';
import '../../training/training_controller_host.dart';
import '../../training/training_settings.dart';
import '../common/app_bar_title.dart';
import '../common/field_label.dart';
import '../responsive.dart';
import 'key_test_area.dart';

/// Keys and external keyers (F12): the device's key profiles, which one is
/// in use, and an editor for each. Profiles are keyboard-binding presets
/// for the keyboard and for keyboard-emulating USB adapters.
class KeySetupPage extends StatelessWidget {
  const KeySetupPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const KeySetupPage()));

  Future<void> _edit(BuildContext context, KeyProfile? profile) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => KeyProfileEditorPage(
            profile:
                profile ??
                KeyProfile.defaults.copyWith(
                  id: 'p${DateTime.now().microsecondsSinceEpoch}',
                ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final profiles = context.watch<KeyProfiles>();
    final active = profiles.active;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.keysTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('keys-new'),
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: Text(
          s.keysNewProfile,
          textScaler: edgeLabelTextScaler(context),
        ),
      ),
      body: ReadableBody(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(s.keysIntro),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: active.id,
                onChanged: (id) async {
                  if (id == null) return;
                  final host = Provider.of<TrainingControllerHost?>(
                    context,
                    listen: false,
                  );
                  await profiles.select(id);
                  await syncLearnKeyerMode(host, profiles.active.keyerMode);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      key: const Key('keys-profile-default'),
                      value: KeyProfile.defaults.id,
                      title: Text(s.keysStandardProfile),
                      subtitle: Text(keyLabels(KeyProfile.defaults.effectiveKeys)),
                    ),
                    for (final p in profiles.saved)
                      RadioListTile<String>(
                        key: Key('keys-profile-${p.id}'),
                        value: p.id,
                        title: Text(p.name.isEmpty ? s.keysUnnamed : p.name),
                        subtitle: Text(keyLabels(p.effectiveKeys)),
                        secondary: IconButton(
                          tooltip: s.keysEdit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, p),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.keysLimitations,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edits one profile: name, key capture per action, paddle orientation,
/// keyer mode, adapter and sidetone switches, and a test area. Saving
/// refuses duplicate and reserved keys.
class KeyProfileEditorPage extends StatefulWidget {
  const KeyProfileEditorPage({
    super.key,
    required this.profile,
    this.testSink,
  });

  final KeyProfile profile;

  /// Echo sink for the test area (tests pass a recording sink).
  final MorseSink? testSink;

  @override
  State<KeyProfileEditorPage> createState() => _KeyProfileEditorPageState();
}

class _KeyProfileEditorPageState extends State<KeyProfileEditorPage> {
  late KeyProfile _draft = widget.profile;
  late final TextEditingController _name = TextEditingController(
    text: widget.profile.name,
  );
  KeyerAction? _capturing;
  final FocusNode _captureFocus = FocusNode(debugLabel: 'key-capture');
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _captureFocus.dispose();
    super.dispose();
  }

  Set<LogicalKeyboardKey> _keysOf(KeyerAction a) => switch (a) {
    KeyerAction.straight => _draft.straight,
    KeyerAction.dit => _draft.dit,
    KeyerAction.dah => _draft.dah,
  };

  String _actionLabel(S s, KeyerAction a) => switch (a) {
    KeyerAction.straight => s.keysActionStraight,
    KeyerAction.dit => s.keysActionDit,
    KeyerAction.dah => s.keysActionDah,
  };

  void _startCapture(KeyerAction action) {
    setState(() {
      _capturing = action;
      _error = null;
    });
    _captureFocus.requestFocus();
  }

  KeyEventResult _onCaptureKey(FocusNode node, KeyEvent event) {
    final action = _capturing;
    if (action == null || event is! KeyDownEvent) {
      // Repeats and key-ups never change a binding.
      return action == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }
    final key = event.logicalKey;
    final s = context.s;
    if (KeyProfile.reservedKeys.contains(key)) {
      setState(() => _error = s.keysReserved(keyLabels({key})));
      return KeyEventResult.handled;
    }
    for (final other in KeyerAction.values) {
      if (other != action && _keysOf(other).contains(key)) {
        setState(
          () => _error = s.keysConflict(keyLabels({key}), _actionLabel(s, other)),
        );
        return KeyEventResult.handled;
      }
    }
    setState(() {
      _draft = switch (action) {
        KeyerAction.straight => _draft.copyWith(straight: {key}),
        KeyerAction.dit => _draft.copyWith(dit: {key}),
        KeyerAction.dah => _draft.copyWith(dah: {key}),
      };
      _capturing = null;
    });
    // Hand the keyboard back to the test key, so the new binding can be
    // tried at once.
    _captureFocus.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    return KeyEventResult.handled;
  }

  Future<void> _save() async {
    final s = context.s;
    final profiles = context.read<KeyProfiles>();
    final host = Provider.of<TrainingControllerHost?>(context, listen: false);
    final navigator = Navigator.of(context);
    final profile = _draft.copyWith(name: _name.text.trim());
    try {
      await profiles.save(profile);
    } on KeyProfileException catch (e) {
      setState(
        () => _error = switch (e.error) {
          KeyProfileError.conflict => s.keysConflictSave(keyLabels(e.keys)),
          KeyProfileError.reserved => s.keysReserved(keyLabels(e.keys)),
          KeyProfileError.missing => s.keysMissing,
        },
      );
      return;
    }
    await syncLearnKeyerMode(host, profile.keyerMode);
    navigator.pop();
  }

  Future<void> _delete() async {
    final profiles = context.read<KeyProfiles>();
    final navigator = Navigator.of(context);
    await profiles.delete(widget.profile.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final exists = context
        .watch<KeyProfiles>()
        .saved
        .any((p) => p.id == widget.profile.id);
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(s.keysEditTitle),
        actions: [
          if (exists)
            IconButton(
              tooltip: s.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ReadableBody(
        child: Focus(
          focusNode: _captureFocus,
          onKeyEvent: _onCaptureKey,
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  key: const Key('keys-name'),
                  controller: _name,
                  decoration: InputDecoration(
                    label: FieldLabel(s.keysName),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                for (final a in KeyerAction.values)
                  ListTile(
                    key: Key('keys-capture-${a.name}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(_actionLabel(s, a)),
                    subtitle: Text(
                      _capturing == a
                          ? s.keysPressKey
                          : _keysOf(a).isEmpty
                          ? s.keysNone
                          : keyLabels(_keysOf(a)),
                    ),
                    trailing: TextButton(
                      onPressed: () => _startCapture(a),
                      child: Text(s.keysSet),
                    ),
                  ),
                if (_error case final String e)
                  Text(
                    e,
                    key: const Key('keys-error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                SwitchListTile(
                  key: const Key('keys-swap'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.keysSwapPaddles),
                  value: _draft.swapPaddles,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(swapPaddles: v)),
                ),
                Text(s.keysKeyerMode, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in KeyerMode.values)
                      ChoiceChip(
                        key: Key('keys-mode-${m.name}'),
                        label: Text(switch (m) {
                          KeyerMode.straight => s.keysActionStraight,
                          KeyerMode.iambicA => s.keysIambicA,
                          KeyerMode.iambicB => s.keysIambicB,
                        }),
                        selected: _draft.keyerMode == m,
                        onSelected: (_) => setState(() => _draft = _draft.copyWith(keyerMode: m)),
                      ),
                  ],
                ),
                SwitchListTile(
                  key: const Key('keys-adapter'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.keysAdapterKeyer),
                  subtitle: Text(s.keysAdapterKeyerHint),
                  value: _draft.adapterKeyer,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(adapterKeyer: v)),
                ),
                SwitchListTile(
                  key: const Key('keys-sidetone'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.keysAppSidetone),
                  subtitle: Text(s.keysAppSidetoneHint),
                  value: _draft.appSidetone,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(appSidetone: v)),
                ),
                const SizedBox(height: 8),
                KeyTestArea(profile: _draft, sink: widget.testSink),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('keys-save'),
                  onPressed: _save,
                  child: Text(s.actionSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Learn keeps its keyer mode in the training settings: follow the active
/// profile so every keying surface runs the same mode. Without an identity
/// or guest profile yet, Learn picks it up from the next save or selection.
Future<void> syncLearnKeyerMode(
  TrainingControllerHost? host,
  KeyerMode mode,
) async {
  if (host == null) return;
  try {
    final c = await host.controller();
    if (c.settings.keyerMode != mode) {
      await c.updateSettings(c.settings.copyWith(keyerMode: mode));
    }
  } on Object {
    // See above.
  }
}
