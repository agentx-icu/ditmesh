import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import 'password_strength.dart';

/// Narrow, centred, scrollable column used by every onboarding page so phones
/// get full width and desktop windows do not stretch forms to 1200 px.
///
/// A `SingleChildScrollView` + `Column`, not a `ListView`: these pages are
/// short forms whose primary button may sit below the fold on a phone, and a
/// lazy list would not build it (breaking `ensureVisible`, semantics and
/// tests alike).
class AccountPageBody extends StatelessWidget {
  const AccountPageBody({
    super.key,
    required this.children,
    this.maxWidth = 480,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Password field with a show/hide toggle and an optional strength hint.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.showStrength = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool showStrength;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final strength = widget.showStrength
        ? ratePassword(widget.controller.text)
        : PasswordStrength.empty;
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        label: FieldLabel(widget.label),
        errorText: widget.errorText,
        helperText: strength == PasswordStrength.empty
            ? null
            : strength.label(s),
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscure ? s.accountShowPassword : s.accountHidePassword,
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Bulleted explanation line used on the welcome and backup pages.
class BulletLine extends StatelessWidget {
  const BulletLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Copies [text] and confirms with a snackbar ("Tox ID copied" unless
/// [confirmation] says otherwise).
Future<void> copyToClipboard(
  BuildContext context,
  String text, {
  String? confirmation,
}) async {
  final message = confirmation ?? context.s.accountCopied;
  final messenger = ScaffoldMessenger.maybeOf(context);
  await Clipboard.setData(ClipboardData(text: text));
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

/// Tox IDs are 76 hex chars; break them into groups so they wrap sanely on a
/// phone and can be read aloud.
String groupToxId(String toxId, {int groupSize = 4}) {
  final buffer = StringBuffer();
  for (var i = 0; i < toxId.length; i += groupSize) {
    if (i > 0) buffer.write(' ');
    final end = i + groupSize > toxId.length ? toxId.length : i + groupSize;
    buffer.write(toxId.substring(i, end));
  }
  return buffer.toString();
}
