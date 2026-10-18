import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';

/// A text field for a Maidenhead locator: capitals keyboard, no autocorrect,
/// and the shared "2, 4, 6 or 8 characters" error while the text is not a
/// locator. Used by the grid, sunrise and beacon tools.
class LocatorField extends StatelessWidget {
  const LocatorField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  /// The trimmed text when it is a well-formed locator, else null.
  static String? locatorOf(TextEditingController controller) {
    final text = controller.text.trim();
    return Maidenhead.isValid(text) ? text : null;
  }

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    final invalid = text.isNotEmpty && !Maidenhead.isValid(text);
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      decoration: InputDecoration(
        label: FieldLabel(label),
        // ui-literal-ok: Maidenhead locator example, identical in every locale
        hintText: 'OM89ex',
        errorText: invalid ? context.s.toolsGridInvalidLocator : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
