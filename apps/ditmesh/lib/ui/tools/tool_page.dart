import 'package:flutter/material.dart';

/// Scaffold shared by every radio tool: one scrolling column, capped at a
/// readable width on desktop and full width (with safe areas) on phones.
class ToolPage extends StatelessWidget {
  const ToolPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  static const double maxContentWidth = 640;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

/// A titled card grouping one calculation.
class ToolSection extends StatelessWidget {
  const ToolSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ...children,
        ],
      ),
    ),
  );
}

/// `label ............ value`, the value selectable so it can be copied
/// into a log. Wraps instead of overflowing on narrow phones.
class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = emphasize
        ? theme.textTheme.headlineSmall?.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          )
        : theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SelectableText(value, style: valueStyle),
        ],
      ),
    );
  }
}

/// Parses a decimal typed with either `.` or `,` as the separator.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
