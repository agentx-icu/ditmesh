import 'package:flutter/material.dart';

/// An [InputDecoration.label] that scales down instead of ending in an
/// ellipsis when a narrow field, a long language or large text leaves it
/// too little width.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(text),
  );
}
