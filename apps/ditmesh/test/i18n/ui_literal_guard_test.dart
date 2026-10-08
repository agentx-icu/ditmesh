import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Exercises `tool/ui_literal_guard.dart` end to end on scratch trees by
/// running it as a subprocess (the tool lives at the repository root, outside
/// this package, so it cannot be imported). The repository root is the
/// working directory so the tool resolves `package:analyzer` from the
/// workspace package config.
void main() {
  late String repoRoot;
  late String dartExe;
  late Directory scratch;

  setUpAll(() {
    repoRoot = _locateRepoRoot();
    dartExe = _locateDart();
  });

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('ditmesh_ui_literal_guard_');
  });

  tearDown(() => scratch.deleteSync(recursive: true));

  void write(String relPath, String source) {
    File('${scratch.path}/apps/ditmesh/lib/$relPath')
      ..createSync(recursive: true)
      ..writeAsStringSync(source);
  }

  Future<ProcessResult> run() => Process.run(
    dartExe,
    ['tool/ui_literal_guard.dart', '--root', scratch.path],
    workingDirectory: repoRoot,
  );

  const timeout = Timeout(Duration(minutes: 3));

  test('clean tree passes: interpolation-only, symbols, non-sinks, '
      'exemptions with a reason, generated files', () async {
    write('ui/interpolation_only.dart', r'''
Widget a(int position, int x, int y) => Column(children: [
  Text('$position'),
  Text('${x} / ${y}'),
  Text('—'),
  const Text('%'),
  Text(context.s.send),
]);
''');
    write('ui/non_sinks.dart', r'''
Widget b() => Column(key: const Key('send-button'), children: [
  Image.asset('assets/tray/icon.png'),
  DropdownMenuItem(value: 'en', child: Text(name)),
  Text(map['title']!),
]);
const labels = {'title': 'Not a sink', 'label': 'Map key'};
final route = GoRoute(path: '/chat/settings', name: 'chatSettings');
''');
    write('ui/exempt.dart', r'''
Widget c() => Column(children: [
  // ui-literal-ok: amateur callsign, never translated
  Text('CQ DE N0CALL'),
  TextField(
    decoration: InputDecoration(hintText: 'OM89ex'), // ui-literal-ok: locator
  ),
]);
''');
    write('l10n/generated/s_en.dart', r'''
Widget d() => Text('Generated text is exempt');
''');
    write('ui/model.g.dart', r'''
Widget e() => Text('Generated part is exempt');
''');

    final result = await run();
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect(
      result.stdout,
      contains('[ui-literal-guard] OK — 3 file(s) scanned'),
    );
  }, timeout: timeout);

  test('flags literals in every kind of sink and bad exemptions', () async {
    write('ui/text.dart', r'''
Widget a() => const Text('Send');
''');
    write('ui/prose_interpolation.dart', r'''
Widget a(int n) => Text('$n items');
''');
    write('ui/text_span.dart', r'''
Widget a() => Text.rich(TextSpan(text: 'Hello', children: [
  const TextSpan(text: ' world'),
]));
''');
    write('ui/decoration.dart', r'''
Widget a(bool bad) => TextField(
  decoration: InputDecoration(
    errorText: bad ? 'Invalid' : null,
    labelText: 'Name' 'here',
  ),
);
''');
    write('ui/tooltip.dart', r'''
Widget a() => IconButton(tooltip: 'Close', icon: Icon(Icons.close));
''');
    write('ui/no_reason.dart', r'''
Widget a() => Text('CQ'); // ui-literal-ok:
''');
    write('ui/unused.dart', r'''
// ui-literal-ok: nothing to exempt here
Widget a() => Text(context.s.send);
''');
    write('ui/trailing_leak.dart', r'''
Widget a() => Column(children: [
  Text('CQ'), // ui-literal-ok: callsign
  Text('Delete account'),
]);
''');
    write('ui/switch_expression.dart', r'''
Widget a(int n) => Text(switch (n) { 1 => 'English', _ => 'Chinese' });
''');
    write('ui/function_call.dart', r'''
Widget a(Widget Function({String? tooltip})? builder) => Column(children: [
  (builder)(tooltip: 'Hardcoded'),
  builder!(tooltip: 'Also hardcoded'),
]);
''');
    write('startup/startup.dart', r'''
Widget a(String? name) => SelectableText(name ?? 'Unknown');
''');

    final result = await run();
    final err = result.stderr as String;
    expect(result.exitCode, 1, reason: '${result.stdout}$err');
    final expected = <String>[
      "decoration.dart:3:22  errorText  'Invalid'",
      "function_call.dart:2:22  tooltip  'Hardcoded'",
      "function_call.dart:3:21  tooltip  'Also hardcoded'",
      "switch_expression.dart:1:43  Text  'English'",
      "switch_expression.dart:1:59  Text  'Chinese'",
      "trailing_leak.dart:3:8  Text  'Delete account'",
      "decoration.dart:4:16  labelText  'Name' 'here'",
      "no_reason.dart:1:20  Text  'CQ'",
      'no_reason.dart:1:27  exemption  `// ui-literal-ok:` needs a reason',
      r"prose_interpolation.dart:1:25  Text  '$n items'",
      "startup.dart:1:50  SelectableText  'Unknown'",
      "text.dart:1:26  Text  'Send'",
      "text_span.dart:1:40  text  'Hello'",
      "text_span.dart:2:24  text  ' world'",
      "tooltip.dart:1:35  tooltip  'Close'",
      'unused.dart:1:1  exemption  unused',
    ];
    for (final line in expected) {
      expect(err, contains(line));
    }
    expect(err, contains('[ui-literal-guard] ${expected.length} violation(s)'));
  }, timeout: timeout);

  test('a file that does not parse fails loudly with its path', () async {
    write('ui/broken.dart', 'Widget a() => Text(;\n');

    final result = await run();
    expect(result.exitCode, 1);
    expect(result.stderr, contains('cannot parse'));
    expect(result.stderr, contains('apps/ditmesh/lib/ui/broken.dart:1:'));
  }, timeout: timeout);
}

String _locateRepoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 5; i++) {
    if (File('${dir.path}/tool/ui_literal_guard.dart').existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  fail('tool/ui_literal_guard.dart not found above ${Directory.current.path}');
}

/// Returns a Dart CLI able to run the tool as a subprocess.
///
/// Under `flutter test` [Platform.resolvedExecutable] is `flutter_tester`
/// (the engine test harness, not a Dart CLI): handing it a script hangs
/// until the test times out. So prefer the `dart` shipped inside the Flutter
/// SDK the harness came from, and fall back to the executable itself only
/// when it already is `dart` (plain `dart test`).
String _locateDart() {
  final exeName = Platform.isWindows ? 'dart.exe' : 'dart';
  final self = File(Platform.resolvedExecutable);
  final selfName = self.uri.pathSegments.last;
  if (selfName == exeName || selfName == 'dart') return self.path;

  final candidates = <String>[];
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    candidates.add('$flutterRoot/bin/cache/dart-sdk/bin/$exeName');
  }
  // flutter_tester lives at <flutter>/bin/cache/artifacts/engine/<os>/; the
  // Dart SDK the same Flutter uses is <flutter>/bin/cache/dart-sdk/.
  var dir = self.parent;
  for (var i = 0; i < 6; i++) {
    candidates.add('${dir.path}/dart-sdk/bin/$exeName');
    dir = dir.parent;
  }
  for (final c in candidates) {
    if (File(c).existsSync()) return c;
  }
  // Last resort: whatever `dart` is on PATH.
  return exeName;
}
