import 'dart:convert';

import '../morse_text.dart';
import 'training_material.dart';

/// Import limits (functional spec §9.1): exceeding any of them rejects the
/// import explicitly; nothing is partially imported.
abstract final class MaterialLimits {
  static const int maxBytes = 1024 * 1024;
  static const int maxEntries = 1000;
  static const int maxSymbolsPerEntry = 200;

  /// Running text is trained in segments of about this many symbols,
  /// split at word boundaries.
  static const int segmentSymbols = 40;
}

/// Why an analysis cannot be committed.
enum MaterialProblem {
  empty,
  tooLarge,
  tooManyEntries,
  entryTooLong,
  nothingTrainable,
}

/// Preview of a text before it becomes a material: counts, segments,
/// unsupported characters, prosigns and duplicates. Nothing is dropped
/// silently — unsupported characters are listed and the learner confirms.
final class MaterialAnalysis {
  const MaterialAnalysis({
    required this.items,
    required this.unsupported,
    required this.prosigns,
    required this.duplicates,
    required this.symbolCount,
    required this.problems,
  });

  /// Trainable items (supported symbols only, normalised).
  final List<String> items;

  /// Characters that cannot be keyed, in order of first appearance.
  final List<String> unsupported;

  /// Prosign tokens such as `<BT>`.
  final int prosigns;

  /// List entries that occur more than once (kept once).
  final List<String> duplicates;
  final int symbolCount;
  final List<MaterialProblem> problems;

  bool get ok => problems.isEmpty;
}

abstract final class MaterialImport {
  /// Analyses [text] as a material of [kind].
  static MaterialAnalysis analyze(String text, MaterialKind kind) {
    final problems = <MaterialProblem>[];
    if (utf8.encode(text).length > MaterialLimits.maxBytes) {
      problems.add(MaterialProblem.tooLarge);
    }
    final unsupported = <String>[];
    var prosigns = 0;
    String clean(String raw) {
      final kept = <String>[];
      for (final token in MorseText.tokenize(raw)) {
        if (token == MorseText.space) {
          if (kept.isNotEmpty && kept.last != MorseText.space) kept.add(token);
          continue;
        }
        if (MorseSupport.isSupported(token)) {
          if (token.startsWith('<')) prosigns++;
          kept.add(token);
        } else if (!unsupported.contains(token)) {
          unsupported.add(token);
        }
      }
      while (kept.isNotEmpty && kept.last == MorseText.space) {
        kept.removeLast();
      }
      return kept.join();
    }

    final items = <String>[];
    final duplicates = <String>[];
    if (kind == MaterialKind.text) {
      items.addAll(segment(clean(text)));
      if (items.length > MaterialLimits.maxEntries) {
        problems.add(MaterialProblem.tooManyEntries);
      }
    } else {
      final lines = const LineSplitter()
          .convert(text)
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.length > MaterialLimits.maxEntries) {
        problems.add(MaterialProblem.tooManyEntries);
      }
      final seen = <String>{};
      for (final line in lines) {
        final item = clean(line);
        if (item.isEmpty) continue;
        if (MorseText.symbols(item).length >
                MaterialLimits.maxSymbolsPerEntry &&
            !problems.contains(MaterialProblem.entryTooLong)) {
          problems.add(MaterialProblem.entryTooLong);
        }
        if (!seen.add(item)) {
          if (!duplicates.contains(item)) duplicates.add(item);
          continue;
        }
        items.add(item);
      }
    }
    final symbols = items.fold<int>(
      0,
      (n, i) => n + MorseText.symbols(i).length,
    );
    if (text.trim().isEmpty) {
      problems.add(MaterialProblem.empty);
    } else if (items.isEmpty) {
      problems.add(MaterialProblem.nothingTrainable);
    }
    return MaterialAnalysis(
      items: items,
      unsupported: unsupported,
      prosigns: prosigns,
      duplicates: duplicates,
      symbolCount: symbols,
      problems: problems,
    );
  }

  /// Splits normalised text into segments of about
  /// [MaterialLimits.segmentSymbols] symbols at word boundaries; a single
  /// word longer than a segment is cut into segment-sized pieces, so every
  /// item respects [MaterialLimits.maxSymbolsPerEntry].
  static List<String> segment(String text) {
    final words = <String>[];
    for (final word in text.split(' ').where((w) => w.isNotEmpty)) {
      final symbols = MorseText.symbols(word);
      for (var i = 0; i < symbols.length; i += MaterialLimits.segmentSymbols) {
        final end = i + MaterialLimits.segmentSymbols;
        words.add(
          symbols
              .sublist(i, end > symbols.length ? symbols.length : end)
              .join(),
        );
      }
    }
    final out = <String>[];
    var current = <String>[];
    var count = 0;
    for (final word in words) {
      final n = MorseText.symbols(word).length;
      if (current.isNotEmpty && count + n > MaterialLimits.segmentSymbols) {
        out.add(current.join(' '));
        current = <String>[];
        count = 0;
      }
      current.add(word);
      count += n;
    }
    if (current.isNotEmpty) out.add(current.join(' '));
    return out;
  }

  /// Builds a material from a confirmed analysis.
  static TrainingMaterial create({
    required String id,
    required String title,
    required MaterialKind kind,
    required String text,
    required MaterialAnalysis analysis,
    required DateTime now,
    List<String> tags = const <String>[],
    MaterialSource? source,
  }) {
    if (!analysis.ok) {
      throw StateError('cannot create a material from ${analysis.problems}');
    }
    return TrainingMaterial(
      id: id,
      title: title,
      kind: kind,
      originalText: text,
      normalizedItems: analysis.items,
      tags: tags,
      source: source,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// What to do with an imported material whose id already exists.
enum DuplicatePolicy { overwrite, keepCopy, skip }

/// The versioned JSON exchange format of a material library.
abstract final class MaterialLibraryCodec {
  static const String format = 'ditmesh-materials';
  static const int version = 1;

  /// Shared exports never contain private local references.
  static String encode(List<TrainingMaterial> materials) =>
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'format': format,
        'version': version,
        'materials': [
          for (final m in materials) m.toJson(includePrivate: false),
        ],
      });

  /// Parses a whole library or throws [FormatException]; never returns a
  /// partial result.
  static List<TrainingMaterial> decode(String raw) {
    try {
      return _decode(raw);
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      // Wrong field types (`"version": "x"`) are malformed input too.
      throw FormatException('malformed material library: $e');
    }
  }

  static List<TrainingMaterial> _decode(String raw) {
    if (utf8.encode(raw).length > MaterialLimits.maxBytes) {
      throw const FormatException('library exceeds 1 MiB');
    }
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      rethrow;
    }
    if (json is! Map<String, Object?> || json['format'] != format) {
      throw const FormatException('not a DitMesh material library');
    }
    final v = (json['version'] as num?)?.toInt() ?? 0;
    if (v < 1 || v > version) {
      throw FormatException('unsupported library version $v');
    }
    final list = json['materials'];
    if (list is! List) throw const FormatException('materials missing');
    if (list.length > MaterialLimits.maxEntries) {
      throw const FormatException('too many materials');
    }
    final out = <TrainingMaterial>[];
    for (final m in list) {
      if (m is! Map<String, Object?>) {
        throw const FormatException('material must be an object');
      }
      final material = TrainingMaterial.fromJson(m);
      for (final item in material.normalizedItems) {
        final symbols = MorseText.symbols(item);
        if (symbols.length > MaterialLimits.maxSymbolsPerEntry ||
            !symbols.every(MorseSupport.isSupported)) {
          throw FormatException('invalid item in ${material.id}');
        }
      }
      out.add(material);
    }
    return out;
  }

  /// Merges [incoming] into [library] following [policy]; [newId] makes ids
  /// for kept copies. Returns the merged library (the input is untouched).
  static List<TrainingMaterial> merge(
    List<TrainingMaterial> library,
    List<TrainingMaterial> incoming, {
    required DuplicatePolicy policy,
    required String Function() newId,
  }) {
    final out = <TrainingMaterial>[...library];
    for (final m in incoming) {
      final at = out.indexWhere((e) => e.id == m.id);
      if (at < 0) {
        out.add(m);
        continue;
      }
      switch (policy) {
        case DuplicatePolicy.overwrite:
          out[at] = m;
        case DuplicatePolicy.keepCopy:
          out.add(m.copyWith(id: newId()));
        case DuplicatePolicy.skip:
          break;
      }
    }
    return out;
  }
}
