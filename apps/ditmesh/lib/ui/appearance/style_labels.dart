import '../../i18n/l10n_extension.dart';
import 'ui_style.dart';

String styleLabel(S s, UiStyle style) => switch (style) {
  UiStyle.white => s.appearanceWhite,
  UiStyle.classic => s.appearanceClassic,
  UiStyle.radio => s.appearanceRadio,
  UiStyle.cartoon => s.appearanceCartoon,
};
