import 'package:flutter/material.dart';

import '../common/field_label.dart';
import 'tool_page.dart';

/// A numeric input shared by the calculators: outlined, decimal keyboard,
/// optional error text. Parse its text with [parseDecimal].
class DecimalField extends StatelessWidget {
  const DecimalField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    onChanged: onChanged,
    decoration: InputDecoration(
      label: FieldLabel(label),
      hintText: hint,
      errorText: errorText,
      border: const OutlineInputBorder(),
    ),
  );
}

/// The field's number when it is finite and above 0, else null.
double? positiveOf(TextEditingController controller) {
  final v = parseDecimal(controller.text);
  return v != null && v.isFinite && v > 0 ? v : null;
}

/// The field's number when it is finite and 0 or more, else null.
double? nonNegativeOf(TextEditingController controller) {
  final v = parseDecimal(controller.text);
  return v != null && v.isFinite && v >= 0 ? v : null;
}

/// The field's number, 0 when the field is empty, null when it is not a
/// finite number.
double? optionalOf(TextEditingController controller) {
  if (controller.text.trim().isEmpty) return 0;
  final v = parseDecimal(controller.text);
  return v != null && v.isFinite ? v : null;
}

/// True when the user typed something that did not parse into the value
/// the tool needs.
bool rejected(TextEditingController controller, double? parsed) =>
    controller.text.trim().isNotEmpty && parsed == null;
