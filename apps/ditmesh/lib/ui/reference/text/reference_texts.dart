import 'reference_text.dart';
import 'reference_text_en.dart';
import 'reference_text_zh.dart';
import 'reference_text_zh_hant.dart';
import 'reference_text_ja.dart';
import 'reference_text_ko.dart';
import 'reference_text_de.dart';
import 'reference_text_fr.dart';
import 'reference_text_es.dart';
import 'reference_text_pt.dart';
import 'reference_text_ru.dart';

export 'reference_text.dart';

/// Every language the reference content ships in, keyed like the ARB files
/// (`en`, `zh`, `zh_Hant`, …). English comes first and is the fallback; a
/// locale reads the most specific key it matches
/// (`referenceLanguageKeys`). Adding a language: add
/// `reference_text_<tag>.dart` with every English row translated and
/// register it here.
const Map<String, ReferenceText> kReferenceTexts = <String, ReferenceText>{
  'en': referenceTextEn,
  'zh': referenceTextZh,
  'zh_Hant': referenceTextZhHant,
  'ja': referenceTextJa,
  'ko': referenceTextKo,
  'de': referenceTextDe,
  'fr': referenceTextFr,
  'es': referenceTextEs,
  'pt': referenceTextPt,
  'ru': referenceTextRu,
};
