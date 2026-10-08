import 'chinese_telegraph_code.dart';

/// What one whitespace-separated token of a message is, for an explicit
/// "interpret as Chinese telegraph code" (F13).
enum TelegraphTokenKind {
  /// Exactly four digits: a code group (possibly unassigned).
  group,

  /// Digits but not four of them (`123`, `12345678`): flagged, never split.
  malformedDigits,

  /// Anything else: kept as written.
  text,
}

/// One token of [TelegraphGroups.parse], in message order.
final class TelegraphToken {
  const TelegraphToken._(this.kind, this.source, this.candidates);

  final TelegraphTokenKind kind;

  /// The token exactly as it appears in the message (leading zeros kept).
  final String source;

  /// Every character the codebook assigns to a [TelegraphTokenKind.group],
  /// in code-point order; empty for an unassigned code and for other kinds.
  final List<String> candidates;

  bool get isGroup => kind == TelegraphTokenKind.group;

  /// A four-digit group the codebook has no character for.
  bool get isUnresolved => isGroup && candidates.isEmpty;

  /// More than one character shares the code (e.g. simplified and
  /// traditional forms): none is chosen silently.
  bool get isAmbiguous => candidates.length > 1;
}

/// Conservative parsing of a message as telegraph code. Unlike
/// [ChineseTelegraphCode.decode] (which extracts digit runs, drops other
/// text, splits long runs and picks the first candidate), this keeps every
/// token, accepts only whitespace-separated four-digit groups, flags other
/// digit runs, and returns all candidates. It never changes the message.
abstract final class TelegraphGroups {
  static final RegExp _group = RegExp(r'^\d{4}$');
  static final RegExp _digits = RegExp(r'^\d+$');

  static List<TelegraphToken> parse(
    String text, {
    TelegraphCodebook codebook = TelegraphCodebook.mainland,
  }) => [
    for (final token in text.split(RegExp(r'\s+')))
      if (token.isNotEmpty) _token(token, codebook),
  ];

  static TelegraphToken _token(String token, TelegraphCodebook codebook) {
    if (_group.hasMatch(token)) {
      return TelegraphToken._(
        TelegraphTokenKind.group,
        token,
        ChineseTelegraphCode.charsOf(token, codebook: codebook),
      );
    }
    if (_digits.hasMatch(token)) {
      return TelegraphToken._(TelegraphTokenKind.malformedDigits, token, const []);
    }
    return TelegraphToken._(TelegraphTokenKind.text, token, const []);
  }

  /// Whether [text] has anything to interpret: at least one whitespace-
  /// separated four-digit group.
  static bool hasGroups(String text) =>
      text.split(RegExp(r'\s+')).any(_group.hasMatch);
}
