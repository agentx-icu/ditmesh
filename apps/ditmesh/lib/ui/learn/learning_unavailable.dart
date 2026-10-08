import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../di/app_features.dart';
import '../../i18n/l10n_extension.dart';

/// Whether learning data that failed to open can be retried in place. In a
/// chat build the usual cause is "no identity yet" (the fix is to create
/// one); the offline build always has its local profile, so a failure is a
/// storage problem worth retrying.
bool learningRetryable(BuildContext context) => !_chat(context);

/// What a learning surface says when its data could not be opened.
String learningUnavailableText(BuildContext context) => _chat(context)
    ? context.s.learnIdentityRequired
    : context.s.learnStorageUnavailable;

bool _chat(BuildContext context) {
  try {
    return context.read<AppFeatures>().chat;
  } on ProviderNotFoundException {
    return true; // widget tests without an AppScope: chat builds' wording
  }
}
