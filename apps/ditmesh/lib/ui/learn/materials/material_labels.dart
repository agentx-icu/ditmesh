import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';

/// Localised material kinds and import problems.
abstract final class MaterialLabels {
  static String kind(S s, MaterialKind kind) => switch (kind) {
    MaterialKind.text => s.materialsKindText,
    MaterialKind.wordList => s.materialsKindWords,
    MaterialKind.callsigns => s.materialsKindCallsigns,
  };

  static String problem(S s, MaterialProblem p) => switch (p) {
    MaterialProblem.empty => s.materialsProblemEmpty,
    MaterialProblem.tooLarge => s.materialsProblemTooLarge,
    MaterialProblem.tooManyEntries => s.materialsProblemTooManyEntries(
      MaterialLimits.maxEntries,
    ),
    MaterialProblem.entryTooLong => s.materialsProblemEntryTooLong(
      MaterialLimits.maxSymbolsPerEntry,
    ),
    MaterialProblem.nothingTrainable => s.materialsProblemNothingTrainable,
  };
}
