import 'dart:io';

/// Layering gate for the ditmesh workspace.
/// Run from the repository root: `dart run tool/import_guard.dart`
///
/// Each [ImportRule] names a set of forbidden `package:` import prefixes and
/// the directory subtrees where the rule is *waived*. Every `.dart` file under
/// the scanned roots that is not inside an allowed subtree and imports (or
/// exports / parts) a forbidden package is reported, and the script exits 1.
///
/// The rule table is data: edit [_rules], not the scanner.
const _rules = <ImportRule>[
  ImportRule(
    name: 'chat-sdk-isolation',
    description:
        'Tim2Tox and the Tencent Cloud Chat SDK may only be imported '
        'inside packages/ditmesh_chat (façade: MorseChatService).',
    forbiddenPrefixes: [
      'package:tim2tox_dart',
      'package:tencent_cloud_chat',
      'package:tencent_im',
    ],
    allowedRoots: ['packages/ditmesh_chat/'],
  ),
  ImportRule(
    name: 'pure-dart-engine',
    description:
        'morse_core, morse_trainer, morse_dsp, radio_tools and '
        'ditmesh_chat_api are pure Dart and must not depend on Flutter.',
    forbiddenPrefixes: ['package:flutter/', 'package:flutter_test/'],
    // The rule only applies inside these subtrees; everything else is exempt.
    appliesOnlyTo: [
      'packages/morse_core/',
      'packages/morse_trainer/',
      'packages/morse_dsp/',
      'packages/radio_tools/',
      'packages/ditmesh_chat_api/',
    ],
  ),
];

/// Top-level directories scanned for `.dart` files. Dot-directories and
/// `build/` trees are pruned during the walk.
const _scanRoots = <String>['packages', 'apps', 'tool'];

void main(List<String> args) {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('[import-guard] run from the repository root');
    exit(1);
  }

  final violations = <String>[];
  var scanned = 0;
  for (final root in _scanRoots) {
    for (final file in _dartFiles(Directory(root))) {
      final path = _normalize(file.path);
      scanned++;
      final imports = _importedUris(file);
      for (final rule in _rules) {
        if (!rule.appliesTo(path)) continue;
        for (final uri in imports) {
          final hit = rule.forbiddenPrefixes.firstWhere(
            uri.startsWith,
            orElse: () => '',
          );
          if (hit.isNotEmpty) {
            violations.add('$path imports "$uri" (rule: ${rule.name})');
          }
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('[import-guard] ${violations.length} violation(s):');
    for (final v in violations..sort()) {
      stderr.writeln('  $v');
    }
    stderr.writeln();
    for (final rule in _rules) {
      stderr.writeln('  ${rule.name}: ${rule.description}');
    }
    exit(1);
  }
  stdout.writeln(
    '[import-guard] OK — $scanned file(s) scanned, '
    '${_rules.length} rule(s), no violations',
  );
}

/// One layering rule. A rule applies to a file when the file is under one of
/// [appliesOnlyTo] (or everywhere when that list is empty) and is *not* under
/// any of [allowedRoots].
class ImportRule {
  const ImportRule({
    required this.name,
    required this.description,
    required this.forbiddenPrefixes,
    this.allowedRoots = const [],
    this.appliesOnlyTo = const [],
  });

  final String name;
  final String description;
  final List<String> forbiddenPrefixes;
  final List<String> allowedRoots;
  final List<String> appliesOnlyTo;

  bool appliesTo(String path) {
    if (allowedRoots.any(path.startsWith)) return false;
    if (appliesOnlyTo.isEmpty) return true;
    return appliesOnlyTo.any(path.startsWith);
  }
}

/// `import` / `export` / `part` directive URIs, single- or double-quoted.
/// Comments are not stripped: a commented-out forbidden import is a smell
/// worth flagging too, and false positives are cheap to fix.
final _directive = RegExp(
  '''^\\s*(?:import|export|part)\\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

Iterable<String> _importedUris(File file) sync* {
  final source = file.readAsStringSync();
  for (final m in _directive.allMatches(source)) {
    yield m.group(1)!;
  }
}

Iterable<File> _dartFiles(Directory dir) sync* {
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entity is Directory) {
      if (name.startsWith('.') || name == 'build') continue;
      yield* _dartFiles(entity);
    } else if (entity is File && name.endsWith('.dart')) {
      yield entity;
    }
  }
}

String _normalize(String p) {
  var s = p.replaceAll('\\', '/');
  if (s.startsWith('./')) s = s.substring(2);
  return s;
}
