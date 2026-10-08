import 'package:morse_core/morse_core.dart';

import '../morse_text.dart';

/// What a material holds (functional spec §9.1).
enum MaterialKind {
  /// Running text, trained in segments.
  text,

  /// One entry per line, sampled randomly.
  wordList,

  /// One callsign per line (format-checked symbols only, never existence).
  callsigns;

  static MaterialKind parse(String? name) =>
      values.firstWhere((v) => v.name == name, orElse: () => MaterialKind.text);
}

/// Where a material came from. [localRef] (e.g. a chat message reference)
/// is private: it is never written into shared exports.
final class MaterialSource {
  const MaterialSource({required this.description, this.localRef});

  final String description;
  final String? localRef;

  Map<String, Object?> toJson({bool includePrivate = true}) =>
      <String, Object?>{
        'description': description,
        if (includePrivate && localRef != null) 'localRef': localRef,
      };

  factory MaterialSource.fromJson(Map<String, Object?> json) => MaterialSource(
    description: json['description'] as String? ?? '',
    localRef: json['localRef'] as String?,
  );
}

/// A learner's own training text, word list or callsign list.
final class TrainingMaterial {
  TrainingMaterial({
    required this.id,
    required this.title,
    required this.kind,
    required this.originalText,
    required List<String> normalizedItems,
    required this.createdAt,
    required this.updatedAt,
    List<String> tags = const <String>[],
    this.favorite = false,
    this.source,
    this.version = currentVersion,
  }) : normalizedItems = List<String>.unmodifiable(normalizedItems),
       tags = List<String>.unmodifiable(tags);

  static const int currentVersion = 1;

  final String id;
  final int version;
  final String title;
  final MaterialKind kind;

  /// Exactly what the learner entered or imported (never rewritten).
  final String originalText;

  /// Trainable items: text segments or list entries, engine-normalised and
  /// containing supported symbols only.
  final List<String> normalizedItems;
  final List<String> tags;
  final bool favorite;
  final MaterialSource? source;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Symbols used by any item.
  Set<String> get symbols => <String>{
    for (final item in normalizedItems) ...MorseText.charSet(item),
  };

  /// Items whose symbols are all in [learned] (learned-only practice); the
  /// rest are unavailable in that mode.
  List<String> itemsWithin(Set<String> learned) =>
      normalizedItems.where((i) => MorseText.usesOnly(i, learned)).toList();

  TrainingMaterial copyWith({
    String? id,
    String? title,
    List<String>? tags,
    bool? favorite,
    DateTime? updatedAt,
    String? originalText,
    List<String>? normalizedItems,
    MaterialKind? kind,
  }) => TrainingMaterial(
    id: id ?? this.id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    originalText: originalText ?? this.originalText,
    normalizedItems: normalizedItems ?? this.normalizedItems,
    tags: tags ?? this.tags,
    favorite: favorite ?? this.favorite,
    source: source,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// [includePrivate] false for shared exports: drops local references.
  Map<String, Object?> toJson({bool includePrivate = true}) =>
      <String, Object?>{
        'id': id,
        'version': version,
        'title': title,
        'kind': kind.name,
        'originalText': originalText,
        'normalizedItems': normalizedItems,
        'tags': tags,
        'favorite': favorite,
        if (source != null)
          'source': source!.toJson(includePrivate: includePrivate),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  /// Throws [FormatException] on anything malformed or from a newer version.
  factory TrainingMaterial.fromJson(Map<String, Object?> json) {
    final version = (json['version'] as num?)?.toInt() ?? 1;
    if (version > currentVersion) {
      throw FormatException('material version $version is newer');
    }
    final id = json['id'];
    final title = json['title'];
    final original = json['originalText'];
    final items = json['normalizedItems'];
    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        original is! String) {
      throw const FormatException('material is missing id/title/text');
    }
    if (items is! List || items.any((i) => i is! String)) {
      throw const FormatException('material items must be strings');
    }
    final rawSource = json['source'];
    return TrainingMaterial(
      id: id,
      version: version,
      title: title,
      kind: MaterialKind.parse(json['kind'] as String?),
      originalText: original,
      normalizedItems: items.cast<String>(),
      tags: (json['tags'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
      favorite: json['favorite'] as bool? ?? false,
      source: rawSource is Map<String, Object?>
          ? MaterialSource.fromJson(rawSource)
          : null,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }
}

/// Engine-level symbol support shared by materials and chat practice.
abstract final class MorseSupport {
  /// Whether a [MorseText] token can be keyed.
  static bool isSupported(String token) => token.startsWith('<')
      ? MorseAlphabet.encodeProsign(token) != null
      : MorseAlphabet.encodeChar(token) != null;

  /// Whether [answer] contains at least one Morse symbol. Blank input —
  /// including non-ASCII whitespace or only unkeyable characters — is not
  /// an answer.
  static bool hasSymbols(String answer) =>
      MorseText.symbols(answer).any(isSupported);
}
