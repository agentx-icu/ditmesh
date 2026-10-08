import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n_extension.dart';
import 'locale_controller.dart';

/// "Language" row for the Me page: shows the current choice and opens a
/// dialog listing "System default" plus every shipped locale by its native
/// name (`LanguageCatalog`), so a new ARB file appears here automatically.
/// Works the same on phone and desktop (plain dialog, no platform pickers).
/// Needs a [LocaleController] provided above it.
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final s = context.s;
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(s.languageTitle),
      subtitle: Text(localeDisplayName(s, controller.locale)),
      onTap: () => showLanguageDialog(context),
    );
  }
}

/// Sentinel tag for "follow the system"; supported locales use
/// [LocaleController.localeName].
const String _systemTag = 'system';

/// Opens the language chooser; resolves when it closes.
Future<void> showLanguageDialog(BuildContext context) {
  final controller = context.read<LocaleController>();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _LanguageDialog(controller: controller),
  );
}

/// The chooser itself. Selecting a language saves it and closes the dialog;
/// while a save is in flight further selections are ignored (one write per
/// choice). A failed save keeps the dialog open with an inline error (a
/// SnackBar would sit behind the modal barrier) and the controller has
/// already rolled back to the previous choice, so the user can retry.
///
/// Closing the dialog (Close, Back, barrier tap) while a save is pending is
/// allowed; the completion then pops nothing, because it only ever closes
/// this dialog's own route while that route is still the current one.
class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog({required this.controller});

  final LocaleController controller;

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _select(String? tag) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.controller.setLocale(
        tag == null || tag == _systemTag
            ? null
            : LocaleController.parseLocaleName(tag),
      );
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final controller = widget.controller;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final current = controller.locale;
        final theme = Theme.of(context);
        // Only the option list scrolls: with every shipped language it is
        // taller than a phone screen, and the save error and Close button
        // must stay in view whichever row was tapped.
        return AlertDialog(
          title: Text(s.languageTitle),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      s.languageSaveFailed,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  child: RadioGroup<String>(
                    groupValue: current == null
                        ? _systemTag
                        : LocaleController.localeName(current),
                    onChanged: _select,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          value: _systemTag,
                          enabled: !_saving,
                          title: Text(localeDisplayName(s, null)),
                        ),
                        for (final locale in LocaleController.supportedLocales)
                          RadioListTile<String>(
                            value: LocaleController.localeName(locale),
                            enabled: !_saving,
                            title: Text(localeDisplayName(s, locale)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.actionClose),
            ),
          ],
        );
      },
    );
  }
}
