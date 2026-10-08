import 'package:flutter/widgets.dart';

import '../l10n/generated/s.dart';

export '../l10n/generated/s.dart' show S;

/// `context.s.chatSend` instead of `S.of(context).chatSend`.
///
/// Requires `S.localizationsDelegates` on the enclosing `MaterialApp`
/// (see lib/l10n/README.md); like `S.of`, it throws below that point.
extension L10nContext on BuildContext {
  S get s => S.of(this);
}
