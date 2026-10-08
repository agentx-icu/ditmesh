import '../../i18n/l10n_extension.dart';
import 'ui_style.dart';

String styleLabel(S s, UiStyle style) => switch (style) {
  UiStyle.classic => s.appearanceClassic,
  UiStyle.modern => s.appearanceModern,
  UiStyle.radio => s.appearanceRadio,
  UiStyle.paper => s.appearancePaper,
  UiStyle.cartoon => s.appearanceCartoon,
};
