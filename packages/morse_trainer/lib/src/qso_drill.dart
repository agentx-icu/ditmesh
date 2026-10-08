import 'dart:math';

import 'callsign_drill.dart';
import 'drill.dart';
import 'word_lists.dart';

/// Templated short QSO exchanges.
///
/// Templates use `{CALL1}`, `{CALL2}`, `{NAME1}`, `{NAME2}`, `{QTH1}`,
/// `{QTH2}`, `{RST}`, `{RIG}` and `{ANT}` placeholders. One generation
/// resolves every placeholder once so a full QSO stays consistent.
///
/// QSOs need most of the alphabet; this drill is meant for the last lessons
/// and does not filter by symbol set. Check [Drill.chars] if you need to.
final class QsoDrill implements DrillGenerator {
  QsoDrill({
    this.full = false,
    CallsignDrill? callsigns,
    List<String> templates = defaultTemplates,
  }) : assert(templates.isNotEmpty, 'templates must not be empty'),
       callsigns = callsigns ?? CallsignDrill(count: 1),
       templates = List<String>.unmodifiable(templates);

  /// A complete QSO script, in order. Prosigns use the `<XX>` form so
  /// `MorseText` scores them as one symbol.
  static const List<String> defaultTemplates = <String>[
    'CQ CQ CQ DE {CALL1} {CALL1} {CALL1} K',
    '{CALL1} DE {CALL2} {CALL2} KN',
    '{CALL2} DE {CALL1} GM OM TNX FER CALL UR RST {RST} {RST} <BT> '
        'NAME IS {NAME1} {NAME1} <BT> QTH {QTH1} {QTH1} HW? {CALL2} DE {CALL1} KN',
    '{CALL1} DE {CALL2} R R FB {NAME1} TNX FER RPRT UR RST {RST} {RST} ES '
        'NAME HR IS {NAME2} {NAME2} <BT> QTH {QTH2} {QTH2} <BT> RIG IS {RIG} '
        'ES ANT IS {ANT} HW? {CALL1} DE {CALL2} K',
    '{CALL2} DE {CALL1} R FB {NAME2} TNX FER QSO ES INFO 73 ES CUL '
        '{CALL2} DE {CALL1} <SK>',
    '{CALL1} DE {CALL2} TU 73 {NAME1} CUL <SK> EE',
  ];

  /// When true every template is emitted in order as one long drill; when
  /// false a single random template is used.
  final bool full;

  final CallsignDrill callsigns;
  final List<String> templates;

  @override
  String get kind => 'qso';

  @override
  Drill generate(Random random) {
    final values = <String, String>{
      '{CALL1}': callsigns.nextCallsign(random),
      '{CALL2}': callsigns.nextCallsign(random),
      '{NAME1}': _pick(random, WordLists.operatorNames),
      '{NAME2}': _pick(random, WordLists.operatorNames),
      '{QTH1}': _pick(random, WordLists.qthNames),
      '{QTH2}': _pick(random, WordLists.qthNames),
      '{RST}': _pick(random, WordLists.rstReports),
      '{RIG}': _pick(random, WordLists.rigNames),
      '{ANT}': _pick(random, WordLists.antennaNames),
    };
    final chosen = full
        ? templates
        : <String>[templates[random.nextInt(templates.length)]];
    final text = chosen.map((t) => _fill(t, values)).join(' ');
    return Drill.fromText(text, kind: kind);
  }

  static String _pick(Random random, List<String> options) =>
      options[random.nextInt(options.length)];

  static String _fill(String template, Map<String, String> values) {
    var out = template;
    for (final entry in values.entries) {
      out = out.replaceAll(entry.key, entry.value);
    }
    return out;
  }
}
