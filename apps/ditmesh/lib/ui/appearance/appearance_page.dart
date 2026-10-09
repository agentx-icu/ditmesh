import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../di/app_settings.dart';
import '../../i18n/l10n_extension.dart';
import '../common/app_bar_title.dart';
import 'style_labels.dart';
import 'style_preview.dart';
import 'ui_style.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  static void open(BuildContext context) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const AppearancePage()));

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  UiStyle? _style;
  ThemeMode? _mode;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.read<AppSettings>();
    _style ??= settings.style;
    _mode ??= settings.themeMode;
  }

  Brightness get _brightness => switch (_mode!) {
    ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
  };

  Future<void> _apply() async {
    final settings = context.read<AppSettings>();
    setState(() => _saving = true);
    try {
      await settings.applyAppearance(style: _style!, themeMode: _mode!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.s.appearanceApplied)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.s.appearanceSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _styles(double width) {
    final columns = width >= 620 ? 3 : 2;
    final cardWidth = (width - 12 * (columns - 1)) / columns;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final style in UiStyle.values)
          SizedBox(
            width: columns == 2 && style == UiStyle.cartoon ? width : cardWidth,
            child: Semantics(
              button: true,
              selected: style == _style,
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: style == _style
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: style == _style ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  key: ValueKey('style-${style.name}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _saving ? null : () => setState(() => _style = style),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                styleLabel(context.s, style),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            if (style == _style)
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ExcludeSemantics(
                          child: StylePreview(
                            style: style,
                            brightness: _brightness,
                            miniature: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _preview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(context.s.appearancePreview),
      StylePreview(
        key: const ValueKey('appearance-preview'),
        style: _style!,
        brightness: _brightness,
      ),
    ],
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _choices(double width) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(context.s.appearanceStyles),
      Text(context.s.appearanceChoose),
      const SizedBox(height: 16),
      _styles(width),
      const SizedBox(height: 24),
      _heading(context.s.appearanceMode),
      // Wrapping choices stay readable at narrow widths and large text.
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final mode in ThemeMode.values)
            ChoiceChip(
              key: ValueKey('mode-${mode.name}'),
              label: Text(switch (mode) {
                ThemeMode.system => context.s.languageSystemDefault,
                ThemeMode.light => context.s.appearanceLight,
                ThemeMode.dark => context.s.appearanceDark,
              }),
              selected: mode == _mode,
              onSelected: _saving ? null : (_) => setState(() => _mode = mode),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final changed = _style != settings.style || _mode != settings.themeMode;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(context.s.appearanceTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: LayoutBuilder(
                builder: (context, inner) {
                  if (inner.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _choices(inner.maxWidth - 320)),
                        const SizedBox(width: 24),
                        SizedBox(width: 296, child: _preview()),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _preview(),
                      const SizedBox(height: 24),
                      _choices(inner.maxWidth),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 640,
                child: FilledButton(
                  key: const ValueKey('appearance-apply'),
                  onPressed: _saving || !changed ? null : _apply,
                  child: Text(context.s.appearanceApply),
                ),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _style = kDefaultUiStyle;
                        _mode = ThemeMode.system;
                      }),
                child: Text(context.s.appearanceRestore),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
