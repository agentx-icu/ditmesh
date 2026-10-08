import '../../../i18n/l10n_extension.dart';

/// Whole-percent accuracy (`0.923` -> `92%`) in the current locale.
String formatAccuracy(S s, double accuracy) =>
    s.learnAccuracyPercent((accuracy * 100).round());

/// One confusion pair: "K heard as M", or "K missed" when nothing was
/// answered for the target.
String confusedAs(S s, String target, String answered) => answered.isEmpty
    ? s.learnConfusedMissed(target)
    : s.learnConfusedAs(target, answered);
