import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Localisation gate: no hard-coded user-visible prose in the app.
/// Run from the repository root: `dart run tool/ui_literal_guard.dart`
/// (`--root <dir>` scans another tree with the same layout; used by tests).
///
/// Every `.dart` file under [_scanRoot] (minus [_excludedPaths]) is parsed with
/// `package:analyzer`. A string literal is reported when it is passed straight
/// into one of the user-visible [_sinks] and its literal text — interpolations
/// removed — contains a Unicode letter. So `Text('$n')`, `'${a} / ${b}'`,
/// `'—'` and `'%'` pass, while `Text('Send')` and `'$n items'` fail. User
/// strings belong in `lib/l10n/app_*.arb` and are read via `context.s`.
///
/// Literals reached through `?:`, `??`, `+`, `switch` expression arms, `as`,
/// `!`, parentheses and `'...'.toUpperCase()`-style calls are checked too, and
/// named sinks apply to function-value calls (`builder!(tooltip: ...)`).
///
/// Exemption: put `// ui-literal-ok: <reason>` at the end of the literal's
/// line (covers that line only) or alone on the line above it. The reason is mandatory, and an
/// exemption that no longer covers a flagged literal is itself a violation,
/// so exemptions stay narrow and cannot go stale. Use it only for content
/// that is not translatable (callsigns, Q-codes, prosigns, locator examples).
///
/// The tables are data: edit [_sinks] / [_excludedPaths], not the scanner.
const _sinks = <UiSink>[
  // Positional first argument of text widgets.
  UiSink.positional('Text'),
  UiSink.positional('SelectableText'),
  // Named arguments that only some callees render.
  UiSink.named('text', callees: {'TextSpan'}),
  UiSink.named('message', callees: {'Tooltip'}),
  UiSink.named('value', callees: {'Semantics'}),
  // Named arguments that are user-visible on any callee (Material widgets,
  // InputDecoration, Semantics, notifications, app helpers).
  UiSink.named('tooltip'),
  UiSink.named('label'),
  UiSink.named('labelText'),
  UiSink.named('hintText'),
  UiSink.named('helperText'),
  UiSink.named('errorText'),
  UiSink.named('counterText'),
  UiSink.named('prefixText'),
  UiSink.named('suffixText'),
  UiSink.named('semanticLabel'),
  UiSink.named('semanticsLabel'),
  UiSink.named('hint'),
  UiSink.named('title'),
  UiSink.named('subtitle'),
  UiSink.named('content'),
];

/// Scanned subtree, relative to the root.
const _scanRoot = 'apps/ditmesh/lib';

/// Generated code is never edited by hand; its strings come from the ARBs.
const _excludedPaths = <ExcludedPath>[
  ExcludedPath.prefix('apps/ditmesh/lib/l10n/generated/'),
  ExcludedPath.suffix('.g.dart'),
  ExcludedPath.suffix('.freezed.dart'),
];

const _marker = 'ui-literal-ok';

void main(List<String> args) {
  var root = '.';
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--root' && i + 1 < args.length) {
      root = args[++i];
    } else {
      stderr.writeln('usage: dart run tool/ui_literal_guard.dart [--root DIR]');
      exit(64);
    }
  }
  final scanDir = Directory('$root/$_scanRoot');
  if (!scanDir.existsSync()) {
    stderr.writeln('[ui-literal-guard] $_scanRoot not found under "$root"; '
        'run from the repository root');
    exit(1);
  }

  final violations = <String>[];
  final parseErrors = <String>[];
  var scanned = 0;
  for (final file in _dartFiles(scanDir)) {
    final path = _relative(file.path, root);
    if (_excludedPaths.any((e) => e.matches(path))) continue;
    scanned++;
    final result = parseString(
      content: file.readAsStringSync(),
      path: file.path,
      throwIfDiagnostics: false,
    );
    if (result.errors.isNotEmpty) {
      for (final e in result.errors) {
        final loc = result.lineInfo.getLocation(e.offset);
        parseErrors.add('$path:${loc.lineNumber}:${loc.columnNumber}  '
            '${e.message}');
      }
      continue;
    }
    violations.addAll(
      _scanUnit(path, result.unit, result.lineInfo, result.content),
    );
  }

  if (parseErrors.isNotEmpty) {
    stderr.writeln('[ui-literal-guard] cannot parse '
        '${parseErrors.length} location(s); fix these first:');
    for (final e in parseErrors) {
      stderr.writeln('  $e');
    }
    exit(1);
  }
  if (violations.isNotEmpty) {
    stderr.writeln('[ui-literal-guard] ${violations.length} violation(s):');
    for (final v in violations) {
      stderr.writeln('  $v');
    }
    stderr
      ..writeln()
      ..writeln('  User-visible text must come from lib/l10n/app_*.arb '
          '(context.s.<key>).')
      ..writeln('  Non-translatable content (callsign, Q-code, locator): '
          'add `// $_marker: <reason>`')
      ..writeln('  at the end of the line or on the line above.');
    exit(1);
  }
  stdout.writeln('[ui-literal-guard] OK — $scanned file(s) scanned, '
      '${_sinks.length} sink(s), no violations');
}

/// One user-visible destination for a string. A [positional] sink is the
/// first positional argument of a call to [callee]; a [named] sink is the
/// named argument [argument], on any callee when [callees] is null.
class UiSink {
  const UiSink.positional(String this.callee)
      : argument = null,
        callees = null;
  const UiSink.named(String this.argument, {this.callees}) : callee = null;

  final String? callee;
  final String? argument;
  final Set<String>? callees;

  String get label => callee ?? argument!;
}

/// A path excluded from the scan, matched on the root-relative path.
class ExcludedPath {
  const ExcludedPath.prefix(this.pattern) : isPrefix = true;
  const ExcludedPath.suffix(this.pattern) : isPrefix = false;

  final String pattern;
  final bool isPrefix;

  bool matches(String path) =>
      isPrefix ? path.startsWith(pattern) : path.endsWith(pattern);
}

class _Exemption {
  _Exemption(this.line, this.column, this.reason, {required this.standalone});
  final int line;
  final int column;
  final String reason;

  /// Nothing but the comment on its line: it then also covers the next line.
  /// A trailing comment covers only its own line.
  final bool standalone;
  bool used = false;
}

List<String> _scanUnit(
  String path,
  CompilationUnit unit,
  LineInfo lines,
  String content,
) {
  final exemptions = _exemptions(unit, lines, content);
  final out = <String>[];
  final visitor = _SinkVisitor((sink, literal) {
    final loc = lines.getLocation(literal.offset);
    final line = loc.lineNumber;
    final above = exemptions[line - 1];
    final ex = exemptions[line] ?? (above?.standalone ?? false ? above : null);
    if (ex != null && ex.reason.isNotEmpty) {
      ex.used = true;
      return;
    }
    final shown = literal.toSource().replaceAll('\n', r'\n');
    out.add('$path:$line:${loc.columnNumber}  ${sink.label}  $shown');
  });
  unit.accept(visitor);
  for (final ex in exemptions.values) {
    if (ex.reason.isEmpty) {
      out.add('$path:${ex.line}:${ex.column}  exemption  '
          '`// $_marker:` needs a reason');
    } else if (!ex.used) {
      out.add('$path:${ex.line}:${ex.column}  exemption  '
          'unused `// $_marker: ${ex.reason}` (remove it)');
    }
  }
  out.sort(_byLocation);
  return out;
}

int _byLocation(String a, String b) {
  List<int> key(String s) =>
      s.split('  ').first.split(':').skip(1).map(int.parse).toList();
  final ka = key(a), kb = key(b);
  return ka[0] != kb[0] ? ka[0] - kb[0] : ka[1] - kb[1];
}

final _markerPattern = RegExp('^//+\\s*$_marker\\b:?(.*)\$');

/// Exemption comments keyed by the line they sit on.
Map<int, _Exemption> _exemptions(
  CompilationUnit unit,
  LineInfo lines,
  String content,
) {
  final found = <int, _Exemption>{};
  Token? token = unit.beginToken;
  while (token != null) {
    Token? comment = token.precedingComments;
    while (comment != null) {
      final m = _markerPattern.firstMatch(comment.lexeme.trim());
      if (m != null) {
        final loc = lines.getLocation(comment.offset);
        final lineStart = lines.getOffsetOfLine(loc.lineNumber - 1);
        found[loc.lineNumber] = _Exemption(
          loc.lineNumber,
          loc.columnNumber,
          m.group(1)!.trim(),
          standalone: content.substring(lineStart, comment.offset).trim().isEmpty,
        );
      }
      comment = comment.next;
    }
    if (token.isEof) break;
    token = token.next;
  }
  return found;
}

class _SinkVisitor extends RecursiveAstVisitor<void> {
  _SinkVisitor(this.report);

  final void Function(UiSink sink, StringLiteral literal) report;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName;
    // `Text.rich(...)` is a named constructor, not the plain `Text` sink.
    final callee = name.name == null ? name.type.name.lexeme : null;
    _checkCall(callee, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Unresolved AST: `Text('x')` without `const`/`new` is a method
    // invocation; `prefix.Text('x')` has an identifier target.
    final target = node.target;
    final isCtorLike = target == null ||
        (target is SimpleIdentifier && _startsLower(target.name));
    _checkCall(isCtorLike ? node.methodName.name : null, node.argumentList);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // `(builder)(tooltip: ...)`, `builder!(tooltip: ...)`: no static callee
    // name, so only the any-callee named sinks apply.
    _checkCall(null, node.argumentList);
    super.visitFunctionExpressionInvocation(node);
  }

  void _checkCall(String? callee, ArgumentList args) {
    final positional =
        args.arguments.where((a) => a is! NamedExpression).firstOrNull;
    for (final sink in _sinks) {
      if (sink.callee != null) {
        if (sink.callee == callee && positional != null) {
          _checkValue(sink, positional);
        }
        continue;
      }
      if (sink.callees != null && !sink.callees!.contains(callee)) continue;
      for (final arg in args.arguments.whereType<NamedExpression>()) {
        if (arg.name.label.name == sink.argument) {
          _checkValue(sink, arg.expression);
        }
      }
    }
  }

  void _checkValue(UiSink sink, Expression value) {
    for (final literal in _literalsIn(value)) {
      if (_hasLetter(literal)) report(sink, literal);
    }
  }
}

bool _startsLower(String s) => s.isNotEmpty && s[0] == s[0].toLowerCase();

/// String literals that flow directly into [e] (through `?:`, `??`, `+`,
/// `switch` expression arms, `as`, `!`, parentheses and calls on a literal).
Iterable<StringLiteral> _literalsIn(Expression e) sync* {
  if (e is StringLiteral) {
    yield e;
  } else if (e is ParenthesizedExpression) {
    yield* _literalsIn(e.expression);
  } else if (e is AsExpression) {
    yield* _literalsIn(e.expression);
  } else if (e is PostfixExpression &&
      e.operator.type == TokenType.BANG) {
    yield* _literalsIn(e.operand);
  } else if (e is SwitchExpression) {
    for (final arm in e.cases) {
      yield* _literalsIn(arm.expression);
    }
  } else if (e is ConditionalExpression) {
    yield* _literalsIn(e.thenExpression);
    yield* _literalsIn(e.elseExpression);
  } else if (e is BinaryExpression &&
      (e.operator.type == TokenType.QUESTION_QUESTION ||
          e.operator.type == TokenType.PLUS)) {
    yield* _literalsIn(e.leftOperand);
    yield* _literalsIn(e.rightOperand);
  } else if (e is MethodInvocation && e.target != null) {
    yield* _literalsIn(e.target!);
  }
}

final _letter = RegExp(r'\p{L}', unicode: true);

/// True when the literal's own text (interpolations excluded) has a letter.
bool _hasLetter(StringLiteral literal) {
  if (literal is SimpleStringLiteral) return _letter.hasMatch(literal.value);
  if (literal is AdjacentStrings) return literal.strings.any(_hasLetter);
  if (literal is StringInterpolation) {
    return literal.elements
        .whereType<InterpolationString>()
        .any((s) => _letter.hasMatch(s.value));
  }
  return false;
}

Iterable<File> _dartFiles(Directory dir) sync* {
  final entries = dir.listSync(followLinks: false)
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in entries) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entity is Directory) {
      if (name.startsWith('.') || name == 'build') continue;
      yield* _dartFiles(entity);
    } else if (entity is File && name.endsWith('.dart')) {
      yield entity;
    }
  }
}

String _relative(String path, String root) {
  var p = path.replaceAll('\\', '/');
  var r = root.replaceAll('\\', '/');
  if (!r.endsWith('/')) r = '$r/';
  if (p.startsWith(r)) p = p.substring(r.length);
  if (p.startsWith('./')) p = p.substring(2);
  return p;
}
