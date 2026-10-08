import 'dart:math';

import 'package:meta/meta.dart';
import 'package:morse_core/morse_core.dart';

import 'drill.dart';

/// Chinese telegraph-code practice (F13). Two skills, kept apart:
///
/// * digit copying — hearing four-digit groups in Morse (scored like any
///   Morse copy, digits only);
/// * codebook recall — knowing which code stands for which character
///   ([TelegraphRecallStats]), which never touches Morse statistics, lesson
///   unlocks or speed advice.
abstract final class TelegraphCurriculum {
  /// A curated introductory list: frequent characters of everyday and
  /// on-air language that both codebooks code (some with different codes).
  static const List<String> introductory = <String>[
    '中', '国', '人', '你', '好', '我', '们', '是', '的', '在', //
    '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', //
    '电', '台', '收', '发', '报', '信', '号', '天', '气', '晴', //
    '雨', '风', '谢', '再', '见', '名', '字', '北', '京', '上', //
    '海', '东', '西', '南', '时', '分', '日', '月', '年', '点', //
  ];

  /// The same list in traditional forms, for the Taiwan codebook.
  static const List<String> introductoryTraditional = <String>[
    '中', '國', '人', '你', '好', '我', '們', '是', '的', '在', //
    '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', //
    '電', '臺', '收', '發', '報', '信', '號', '天', '氣', '晴', //
    '雨', '風', '謝', '再', '見', '名', '字', '北', '京', '上', //
    '海', '東', '西', '南', '時', '分', '日', '月', '年', '點', //
  ];

  /// The curated list in the forms [codebook] codes.
  static List<String> introductoryFor(TelegraphCodebook codebook) => coded(
    codebook == TelegraphCodebook.taiwan
        ? introductoryTraditional
        : introductory,
    codebook,
  );

  /// [chars] that [codebook] has a code for, in order.
  static List<String> coded(
    Iterable<String> chars,
    TelegraphCodebook codebook,
  ) => [
    for (final c in chars)
      if (ChineseTelegraphCode.codeOf(c, codebook: codebook) != null) c,
  ];

  /// Reference to store with an attempt so results stay interpretable
  /// after a table update: `telegraph:<codebook>:<Unihan version>`.
  static String sourceRef(TelegraphCodebook codebook) =>
      'telegraph:${codebook.name}:${ChineseTelegraphCode.unicodeVersion}';

  /// The codebook of a [sourceRef], or null when it is not one.
  static TelegraphCodebook? codebookOf(String? sourceRef) {
    final parts = sourceRef?.split(':');
    if (parts == null || parts.length != 3 || parts[0] != 'telegraph') {
      return null;
    }
    for (final b in TelegraphCodebook.values) {
      if (b.name == parts[1]) return b;
    }
    return null;
  }
}

/// Digit copying of real telegraph codes: each round is [groupCount]
/// four-digit groups for characters from [chars] in [codebook], leading
/// zeros kept. Scored as ordinary Morse digits.
final class TelegraphDigitsDrill implements DrillGenerator {
  TelegraphDigitsDrill({
    required Iterable<String> chars,
    this.codebook = TelegraphCodebook.mainland,
    this.groupCount = 1,
  }) : assert(groupCount > 0, 'groupCount must be positive'),
       codes = List.unmodifiable({
         for (final c in chars)
           ?ChineseTelegraphCode.codeOf(c, codebook: codebook),
       });

  /// Builds a drill over exactly these four-digit [codes] (e.g. the groups
  /// of a chat message); anything that is not four digits is ignored.
  TelegraphDigitsDrill.ofCodes(
    Iterable<String> codes, {
    this.codebook = TelegraphCodebook.mainland,
    this.groupCount = 1,
  }) : codes = List.unmodifiable({
         for (final c in codes)
           if (RegExp(r'^\d{4}$').hasMatch(c)) c,
       });

  static const Set<String> digitSymbols = <String>{
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
  };

  final TelegraphCodebook codebook;
  final int groupCount;

  /// Distinct four-digit codes the rounds draw from.
  final List<String> codes;

  bool get canGenerate => codes.isNotEmpty;

  @override
  String get kind => 'telegraph';

  @override
  Drill generate(Random random) {
    if (!canGenerate) throw StateError('no telegraph codes to drill');
    final groups = [
      for (var i = 0; i < groupCount; i++) codes[random.nextInt(codes.length)],
    ];
    return Drill(text: groups.join(' '), chars: digitSymbols, kind: kind);
  }
}

/// Which way a recall card asks.
enum TelegraphRecallDirection {
  /// Shown a character, answer its four digits.
  charToCode,

  /// Shown four digits, pick the character.
  codeToChar,
}

/// One recall card: the prompt, its accepted answers, and for
/// [TelegraphRecallDirection.codeToChar] the choices offered.
@immutable
final class TelegraphRecallCard {
  const TelegraphRecallCard({
    required this.direction,
    required this.char,
    required this.code,
    required this.accepted,
    this.choices = const [],
  });

  final TelegraphRecallDirection direction;
  final String char;
  final String code;

  /// Every answer that counts as correct: the code, or every character the
  /// codebook assigns to it (equivalent forms are never learner errors).
  final Set<String> accepted;
  final List<String> choices;

  bool isCorrect(String answer) => accepted.contains(answer.trim());

  /// A card for [char] in [codebook]; [distractors] supply wrong choices.
  static TelegraphRecallCard make(
    String char,
    TelegraphRecallDirection direction,
    TelegraphCodebook codebook,
    Random random, {
    List<String> distractors = const [],
  }) {
    final code = ChineseTelegraphCode.codeOf(char, codebook: codebook);
    if (code == null) throw ArgumentError.value(char, 'char', 'not coded');
    if (direction == TelegraphRecallDirection.charToCode) {
      return TelegraphRecallCard(
        direction: direction,
        char: char,
        code: code,
        accepted: {code},
      );
    }
    final same = ChineseTelegraphCode.charsOf(code, codebook: codebook).toSet();
    final wrong = [
      for (final d in distractors)
        if (!same.contains(d) && d != char) d,
    ]..shuffle(random);
    final choices = [char, ...wrong.take(3)]..shuffle(random);
    return TelegraphRecallCard(
      direction: direction,
      char: char,
      code: code,
      accepted: same.isEmpty ? {char} : same,
      choices: choices,
    );
  }
}

/// Mapping statistics of codebook recall, per codebook and character. Kept
/// separately from Morse statistics; assisted answers are counted apart and
/// never as known.
@immutable
final class TelegraphRecallStats {
  const TelegraphRecallStats(this._entries);

  static const TelegraphRecallStats empty = TelegraphRecallStats({});

  static const int version = 1;

  /// `codebook/table/char` → (seen, correct, assisted). The mapping-table
  /// version is part of the key, so results stay tied to the table they
  /// were recorded against after an update.
  final Map<String, (int, int, int)> _entries;

  static String _key(TelegraphCodebook b, String char) =>
      '${b.name}/${ChineseTelegraphCode.unicodeVersion}/$char';

  /// Written by a newer DitMesh: must not be overwritten by this one.
  static bool isNewer(Map<String, Object?>? json) {
    final v = json?['v'];
    return v is int && v > version;
  }

  /// Records one answered card.
  TelegraphRecallStats record(
    TelegraphCodebook codebook,
    String char, {
    required bool correct,
    required bool assisted,
  }) {
    final key = _key(codebook, char);
    final (seen, ok, help) = _entries[key] ?? (0, 0, 0);
    return TelegraphRecallStats({
      ..._entries,
      key: (seen + 1, ok + (correct && !assisted ? 1 : 0), help + (assisted ? 1 : 0)),
    });
  }

  /// (seen, correct unassisted, assisted) of [char] in [codebook].
  (int, int, int) of(TelegraphCodebook codebook, String char) =>
      _entries[_key(codebook, char)] ?? (0, 0, 0);

  /// Unassisted accuracy over [codebook] (0 when nothing was answered).
  double accuracy(TelegraphCodebook codebook) {
    var seen = 0;
    var ok = 0;
    _entries.forEach((k, v) {
      if (k.startsWith('${codebook.name}/')) {
        seen += v.$1 - v.$3;
        ok += v.$2;
      }
    });
    return seen <= 0 ? 0 : ok / seen;
  }

  /// Answered cards in [codebook].
  int answered(TelegraphCodebook codebook) => _entries.entries
      .where((e) => e.key.startsWith('${codebook.name}/'))
      .fold(0, (n, e) => n + e.value.$1);

  Map<String, Object?> toJson() => {
    'v': version,
    'entries': {
      for (final MapEntry(:key, :value) in _entries.entries)
        key: [value.$1, value.$2, value.$3],
    },
  };

  /// Malformed or foreign-version documents load empty.
  static TelegraphRecallStats fromJson(Map<String, Object?>? json) {
    if (json == null || json['v'] != version) return empty;
    final raw = json['entries'];
    if (raw is! Map) return empty;
    final out = <String, (int, int, int)>{};
    raw.forEach((k, v) {
      if (k is String && v is List && v.length == 3 && v.every((x) => x is int)) {
        out[k] = (v[0] as int, v[1] as int, v[2] as int);
      }
    });
    return TelegraphRecallStats(out);
  }
}
