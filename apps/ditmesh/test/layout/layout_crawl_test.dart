// Layout crawl: boots the seeded app at one window profile (phone, landscape
// phone with a keyboard, Split View, tablet, desktop from the minimum window
// to an ultrawide, fractional and integer device pixel ratios, large text,
// long locales) and taps through every reachable screen, dialog and sheet,
// collecting every layout error (overflow, unbounded constraints, ...), text
// under a notch or the home indicator, and controls stretched across a wide
// window, each with the scene that produced it. Two roots per profile: the
// shell (its four tabs), and the training screens chat reaches only three
// levels down (copy practice of a received message, group practice), opened
// directly over the seeded app. One test per root and profile so a failure
// names both.
//
// Opt-in (it taps a few thousand controls); the Layout workflow runs it
// sharded, with Noto as the UI font. Measured with the test font's square
// glyphs Latin text is ~1.8x too wide, so without a real font it is a
// deliberately pessimistic run.
//
//   flutter test test/layout/layout_crawl_test.dart --no-pub \
//       --dart-define=DITMESH_LAYOUT_CRAWL=true \
//       [--dart-define=DITMESH_MATRIX_FONT=<ttf/ttc>] \
//       [--dart-define=DITMESH_MATRIX_MONO_FONT=<ttf/ttc>] \
//       [--dart-define=DITMESH_CRAWL_ONLY=phone-small,desktop-min] \
//       [--dart-define=DITMESH_CRAWL_OUT=<dir>]   one problem file per test
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:provider/provider.dart';
import 'package:ditmesh/training/chat_copy_session.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/ui/chat/conversation_header.dart';
import 'package:ditmesh/ui/chat/conversation_route.dart';
import 'package:ditmesh/ui/groups/practice/group_practice_page.dart';
import 'package:ditmesh/ui/learn/chat_copy/chat_copy_screen.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';

import '../../integration_test/support/seed_data.dart' show SeededBackend;
import '../learn/helpers/fake_playback.dart';
import 'layout_profiles.dart';
import 'seeded_app.dart';

const bool _enabled = bool.fromEnvironment('DITMESH_LAYOUT_CRAWL');
const String _font = String.fromEnvironment('DITMESH_MATRIX_FONT');
const String _mono = String.fromEnvironment('DITMESH_MATRIX_MONO_FONT');
const String _only = String.fromEnvironment('DITMESH_CRAWL_ONLY');
const bool _trace = bool.fromEnvironment('DITMESH_CRAWL_TRACE');

/// Directory that receives `<profile>.txt` with one problem per line.
const String _out = String.fromEnvironment('DITMESH_CRAWL_OUT');

/// Taps per screen; generous, the crawl dedupes by control description.
const int _maxTapsPerScreen = 60;

/// Tab → screen → screen. Deeper flows are covered by their own tests.
const int _maxDepth = 2;

/// Long presses per screen, after the taps.
const int _maxLongPressesPerScreen = 20;

/// Times a screen closed by one of its own controls is reopened.
const int _maxReopen = 12;

/// One gesture on one control of the top route.
typedef _Control = ({Finder finder, String id, String label, bool long});

/// Where a crawl starts: the app shell with its tabs, or the training
/// screens chat opens (copy practice, group practice).
enum CrawlRoot { shell, practice }

void main() {
  setUpAll(() async {
    if (!_enabled || _font.isEmpty) return;
    Future<void> load(String family, String path) async {
      final bytes = ByteData.sublistView(File(path).readAsBytesSync());
      await (FontLoader(family)..addFont(Future.value(bytes))).load();
    }

    await load('Roboto', _font);
    await load('monospace', _mono.isEmpty ? _font : _mono);
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  final wanted = _only.isEmpty ? null : _only.split(',').toSet();
  for (final root in CrawlRoot.values) {
    for (final profile in kLayoutProfiles) {
      if (wanted != null && !wanted.contains(profile.name)) continue;
      testWidgets(
        'layout crawl ${root.name} [${profile.name}]',
        (tester) => _Crawler(tester, profile, root).run(),
        skip: !_enabled,
        timeout: const Timeout(Duration(minutes: 20)),
      );
    }
  }
}

class _Crawler {
  _Crawler(this.tester, this.profile, this.root);

  final WidgetTester tester;
  final LayoutProfile profile;
  final CrawlRoot root;
  final List<String> problems = [];
  final Set<String> visited = {};
  String scene = 'boot';
  int boots = 0;

  final List<String> other = [];

  Future<void> run() async {
    applyProfile(tester, profile);
    _silencePlugins();
    final original = FlutterError.onError;
    FlutterError.onError = (details) => _record(_describe(details));
    // Stray asynchronous errors (a plugin the test host lacks) land in this
    // zone instead of aborting the crawl; the body's own outcome goes
    // through the completer.
    final done = Completer<(Object, StackTrace)?>();
    runZonedGuarded(
      () => unawaited(
        _walk().then(
          (_) => done.complete(null),
          onError: (Object e, StackTrace st) => done.complete((e, st)),
        ),
      ),
      (e, _) => _record('[$scene] ${_firstLine('$e')}'),
    );
    final error = await done.future;
    FlutterError.onError = original;
    if (error != null) Error.throwWithStackTrace(error.$1, error.$2);
    if (_trace) {
      // ignore: avoid_print
      print(visited.join('\n'));
    }
    // ignore: avoid_print
    print(
      '[crawl ${root.name} ${profile.name}] ${visited.length} controls, $boots boot(s)'
      '${other.isEmpty ? '' : '; non-layout errors:\n${other.toSet().join('\n')}'}',
    );
    final unique = problems.toSet().toList();
    if (_out.isNotEmpty) {
      final lines = [
        ...unique.map((p) => 'LAYOUT $p'),
        ...other.toSet().map((p) => 'OTHER $p'),
      ];
      await tester.runAsync(
        () => File(
          '$_out/${root.name}-${profile.name}.txt',
        ).writeAsString(lines.isEmpty ? '' : '${lines.join('\n')}\n'),
      );
    }
    if (unique.isNotEmpty) {
      fail(
        '${unique.length} layout problem(s) at ${root.name} '
        '${profile.name}:\n'
        '${unique.join('\n')}',
      );
    }
  }

  Future<void> _walk() async {
    await _boot();
    final int entries = root == CrawlRoot.shell
        ? kShellDestinations.length
        : _practiceEntries;
    for (var tab = 0; tab < entries; tab++) {
      scene = 'tab $tab';
      await _ensureShell(tab);
      await _crawl(0, 'tab:$tab');
    }
    scene = 'teardown';
    await tester.pumpWidget(const SizedBox());
    await _settle();
  }

  /// Layout failures fail the profile; anything else (a plugin the test
  /// host lacks, a fake that does not implement a call) is reported only.
  void _record(String problem) =>
      (_layoutError.hasMatch(problem) ? problems : other).add(problem);

  static final RegExp _layoutError = RegExp(
    r'overflowed|RenderBox was not laid out|BoxConstraints|unbounded|'
    r'infinite size|needs-layout|NEEDS-LAYOUT|Viewport|hasSize|'
    r'RenderFlex|incoming width|incoming height|was given an infinite|'
    r'outside the safe area|px wide \(readable|truncated ',
  );

  /// Plugins the crawl reaches (microphone, links, sharing, files) answer
  /// with nothing instead of a MissingPluginException.
  void _silencePlugins() {
    final messenger = tester.binding.defaultBinaryMessenger;
    for (final name in _pluginChannels) {
      final channel = MethodChannel(name);
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    }
  }

  static const List<String> _pluginChannels = [
    'com.llfbandit.record/messages',
    'plugins.flutter.io/url_launcher',
    'dev.fluttercommunity.plus/share',
    'miguelruivo.flutter.plugins.filepicker',
    'dev.steenbakker.mobile_scanner/scanner/method',
  ];

  /// The route the crawl returns to between entries; null for the shell
  /// (the first route).
  Route<dynamic>? _base;

  bool _isBase(Route<dynamic> route) =>
      _base == null ? route.isFirst : route == _base || route.isFirst;

  bool get _rootGone =>
      find.byType(AppShell, skipOffstage: false).evaluate().isEmpty;

  /// The seeded data of the current boot.
  late SeededBackend _seed;

  /// Copy practice of a received message, and group practice.
  static const int _practiceEntries = 2;

  /// Opens practice entry [entry] the way chat does, over the shell.
  Future<void> _openPractice(int entry) async {
    final BuildContext context = tester.element(find.byType(AppShell));
    final Widget page;
    if (entry == 0) {
      final TrainingController? controller = await tester.runAsync(
        () => context.read<TrainingControllerHost>().controller(),
      );
      page = ChatCopyScreen(
        controller: controller!,
        playback: FakeLearnPlaybackFactory(),
        session: ChatCopySession(
          text: _seed.copy.qso.first.text,
          conversationId: _seed.qsoConversationId,
          messageId: 'crawl',
          profileKey: controller.profileKey,
          timing: const MorseTiming(wpm: 20),
          toneHz: 700,
        ),
      );
    } else {
      page = GroupPracticePage(
        conversationId: _seed.groupConversationId,
        groupTitle: _seed.copy.groupName,
      );
    }
    final route = MaterialPageRoute<void>(builder: (_) => page);
    _base = route;
    unawaited(_rootNavigator.push(route));
    await _settle();
  }

  Future<void> _boot() async {
    boots++;
    _base = null;
    _seed = await pumpSeededApp(
      tester,
      locale: profile.locale,
      key: ValueKey<int>(boots),
    );
  }

  /// Lets file I/O finish and animations settle, except that a screen animating for ever (a playback
  /// indicator waiting on a fake clock) counts as settled after a few
  /// seconds instead of failing the crawl: the frame is still checked.
  Future<void> _settle() async {
    await tester.runAsync(() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
    } on FlutterError catch (e) {
      if (!e.message.startsWith('pumpAndSettle timed out')) rethrow;
    }
  }

  NavigatorState get _rootNavigator =>
      tester.state<NavigatorState>(find.byType(Navigator).first);

  Route<dynamic>? get _top => topRoute(_rootNavigator);

  Finder get _navHost =>
      find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar);

  /// Back to the shell on [tab], rebooting when a crawled action left it
  /// (locked the identity, deleted it, ...).
  Future<void> _ensureShell(int tab) async {
    if (_rootGone) await _boot();
    if (root == CrawlRoot.practice) {
      _base = null;
      _rootNavigator.popUntil((r) => r.isFirst);
      await _settle();
      if (_rootGone) await _boot();
      await _openPractice(tab);
      _checkSafeArea();
      _checkStretch();
      _checkTruncated();
      return;
    }
    _rootNavigator.popUntil(_isBase);
    await _settle();
    if (_rootGone) await _boot();
    final d = kShellDestinations[tab];
    for (final icon in [d.icon, d.selectedIcon]) {
      final f = find.descendant(of: _navHost, matching: find.byIcon(icon));
      if (f.evaluate().isNotEmpty) {
        await tester.ensureVisible(f.first);
        await tester.tap(f.first, warnIfMissed: false);
        await _settle();
        _checkSafeArea();
        _checkStretch();
        _checkTruncated();
        return;
      }
    }
  }

  /// Crawls the screen on top of the root navigator. [path] identifies it.
  /// Returns false when a tap closed the screen before every control was
  /// tried (a dialog's Close, a form's Save), so the caller reopens it.
  Future<bool> _crawl(int depth, String path) async {
    final Route<dynamic>? home = _top;
    final int tab = int.parse(path.split('>').first.substring(4));
    // Every tap first, then the long presses with their own budget: a list
    // of 43 long-pressable rows must not use up the taps of the app bar.
    for (final bool long in <bool>[false, true]) {
      final int budget = long ? _maxLongPressesPerScreen : _maxTapsPerScreen;
      for (var n = 0; n < budget; n++) {
        if (home != null && !home.isActive) return false;
        final next = _nextControl(long: long);
        if (next == null) break;
        if (!await _try(next, depth, path, home, tab)) return false;
      }
    }
    return true;
  }

  /// Runs [next] and crawls what it opens. False when it closed [home].
  Future<bool> _try(
    _Control next,
    int depth,
    String path,
    Route<dynamic>? home,
    int tab,
  ) async {
    visited.add(next.id);
    if (!await _tap(next, '$path > ${next.label}', tab)) return true;
    var opened = _opened(home);
    for (var reopen = 0; opened && depth < _maxDepth; reopen++) {
      final done = await _crawl(depth + 1, '$path>${next.label}');
      if (done || reopen == _maxReopen) break;
      await _restore(home, tab);
      final again = _nextControl(id: next.id);
      if (again == null || !await _tap(again, scene, tab)) break;
      opened = _opened(home);
    }
    if (home != null && !home.isActive) return false;
    await _restore(home, tab);
    return true;
  }

  /// A new screen, dialog or sheet is on top of [home] (not [home] closing).
  bool _opened(Route<dynamic>? home) {
    final Route<dynamic>? now = _top;
    return now != null && now != home && (home == null || home.isActive);
  }

  Future<bool> _tap(_Control control, String where, int tab) async {
    scene = where;
    try {
      await tester.ensureVisible(control.finder);
      await tester.pump();
      final hit = control.finder.hitTestable();
      if (hit.evaluate().isEmpty) return false;
      if (control.long) {
        await tester.longPress(hit.first);
      } else {
        await tester.tap(hit.first);
      }
      await _settle();
      _checkSafeArea();
      _checkStretch();
      _checkTruncated();
    } on Object catch (e) {
      _record('[$scene] tap failed: ${_firstLine('$e')}');
    }
    if (_rootGone &&
        find.byType(Navigator, skipOffstage: false).evaluate().isEmpty) {
      await _ensureShell(tab);
      return false;
    }
    return true;
  }

  Future<void> _restore(Route<dynamic>? home, int? tab) async {
    if (_rootGone &&
        find.byType(Navigator, skipOffstage: false).evaluate().isEmpty) {
      await _ensureShell(tab ?? 0);
      return;
    }
    final nav = _rootNavigator;
    if (home != null && home.isActive) {
      nav.popUntil((r) => r == home);
    } else {
      nav.popUntil(_isBase);
    }
    await _settle();
    if (_rootGone) {
      await _ensureShell(tab ?? 0);
    }
  }

  /// Flags text on the top route that lies under a notch, the status bar,
  /// or the home indicator. Text inside a vertical scroll
  /// view is only checked sideways (it may legitimately scroll under the
  /// bars); text in a horizontal one is not checked.
  void _checkSafeArea() {
    final FakeViewPadding pad = profile.padding;
    final Size size = profile.size;
    final Rect safe = Rect.fromLTRB(
      pad.left,
      pad.top,
      size.width - pad.right,
      // Not the keyboard: whether one is up depends on a focused field,
      // and the Scaffold already resizes for it (an overflow, if any).
      size.height - pad.bottom,
    );
    if (safe == Offset.zero & size) return;
    final Route<dynamic>? top = _top;
    final String screen = _screenSignature();
    for (final element in find.byType(RichText).evaluate()) {
      if (ModalRoute.of(element) != top) continue;
      final RenderObject? render = element.renderObject;
      if (render is! RenderBox || !render.attached || !render.hasSize) {
        continue;
      }
      final Rect rect = render.localToGlobal(Offset.zero) & render.size;
      if (rect.width < 1 || rect.height < 1) continue;
      Axis? scroll;
      var field = false;
      element.visitAncestorElements((a) {
        // A field's label and hint are clipped by the decorator by design.
        if (a.widget is InputDecorator) {
          field = true;
          return false;
        }
        if (a.widget is Scrollable) {
          scroll =
              (a.widget as Scrollable).axisDirection == AxisDirection.down ||
                  (a.widget as Scrollable).axisDirection == AxisDirection.up
              ? Axis.vertical
              : Axis.horizontal;
          return false;
        }
        return true;
      });
      if (field || scroll == Axis.horizontal) continue;
      const double slack = 0.5;
      final bool sideways =
          rect.left < safe.left - slack || rect.right > safe.right + slack;
      final bool vertical =
          scroll == null &&
          (rect.top < safe.top - slack || rect.bottom > safe.bottom + slack);
      if (!sideways && !vertical) continue;
      final String text = (element.widget as RichText).text.toPlainText();
      if (text.trim().isEmpty) continue;
      final String clipped = text.length > 40 ? text.substring(0, 40) : text;
      _record(
        '[$scene] text "${clipped.replaceAll('\n', ' ')}" on $screen lies '
        'outside the safe area: ${_rect(rect)} vs ${_rect(safe)} '
        'in ${_ancestry(element)}',
      );
    }
  }

  /// Flags interface strings cut short: an app-bar title, a field's hint,
  /// label or helper, or the label of a button, chip, segment or tab that
  /// ends in an ellipsis or loses lines. Names and message previews (user
  /// data in list rows) may be ellipsised on purpose and are not checked.
  void _checkTruncated() {
    final Route<dynamic>? top = _top;
    final String screen = _screenSignature();
    for (final element in find.byType(RichText).evaluate()) {
      if (ModalRoute.of(element) != top) continue;
      final RenderObject? render = element.renderObject;
      if (render is! RenderParagraph || !render.hasSize) continue;
      if (!render.didExceedMaxLines) continue;
      String? where;
      element.visitAncestorElements((a) {
        final w = a.widget;
        // User data (names, previews) may be ellipsised on purpose.
        if (w is ListTile || w is ConversationTitle) return false;
        if (w is AppBar) {
          where = 'app-bar title';
        } else if (w is InputDecorator) {
          where = 'field hint or label';
        } else if (w is ButtonStyleButton ||
            w is SegmentedButton ||
            w is RawChip ||
            w is Tab) {
          where = '${w.runtimeType} label';
        }
        return where == null;
      });
      if (where == null) continue;
      final String text = render.text.toPlainText().replaceAll('\n', ' ');
      _record(
        '[$scene] truncated $where "${text.length > 40 ? text.substring(0, 40) : text}" '
        'on $screen',
      );
    }
  }

  /// Flags list rows, text fields and buttons stretched across a wide
  /// window: past [_maxReadableWidth] a row's title and its trailing
  /// control end up a screen apart.
  void _checkStretch() {
    if (profile.size.width < 1400) return;
    final Route<dynamic>? top = _top;
    final String screen = _screenSignature();
    final finder = find.byWidgetPredicate(
      (w) => w is ListTile || w is TextField || w is ButtonStyleButton,
    );
    for (final element in finder.evaluate()) {
      if (ModalRoute.of(element) != top) continue;
      final RenderObject? render = element.renderObject;
      if (render is! RenderBox || !render.hasSize) continue;
      if (render.size.width <= _maxReadableWidth) continue;
      // Once per screen and kind of control, not per row.
      _stretched.add('${element.widget.runtimeType} on $screen');
    }
    for (final what in _stretched) {
      _record(
        '$what is more than ${_maxReadableWidth.toStringAsFixed(0)} '
        'px wide (readable maximum)',
      );
    }
  }

  static const double _maxReadableWidth = 1100;
  final Set<String> _stretched = {};

  /// The nearest public widget types above [element], innermost first.
  static String _ancestry(Element element) {
    final names = <String>[];
    element.visitAncestorElements((a) {
      final name = a.widget.runtimeType.toString();
      if (!name.startsWith('_') && names.lastOrNull != name) names.add(name);
      return names.length < 8;
    });
    return names.join(' < ');
  }

  static String _rect(Rect r) =>
      '(${r.left.toStringAsFixed(0)},${r.top.toStringAsFixed(0)})-'
      '(${r.right.toStringAsFixed(0)},${r.bottom.toStringAsFixed(0)})';

  /// The first gesture on the top route not yet tried, or the one [id]: a
  /// tap, and a long press where the control has one (reference tiles open
  /// their detail dialog on a long press).
  _Control? _nextControl({String? id, bool? long}) {
    final screen = _screenSignature();
    final Route<dynamic>? top = _top;
    for (final element
        in find.byWidgetPredicate(_isTappable, skipOffstage: true).evaluate()) {
      if (_insideExcluded(element)) continue;
      // Only the top route's controls; the ones below are behind it.
      if (ModalRoute.of(element) != top) continue;
      final label = _labelOf(element);
      if (label.isEmpty) continue;
      final Widget w = element.widget;
      for (final bool gesture in <bool>[
        if (w is! InkResponse || w.onTap != null) false,
        if (w is InkResponse && w.onLongPress != null) true,
      ]) {
        if (long != null && gesture != long) continue;
        final key = '$screen|$label${gesture ? ' (long press)' : ''}';
        if (id != null ? key != id : visited.contains(key)) continue;
        return (
          finder: find.byElementPredicate((e) => identical(e, element)),
          id: key,
          label: '${gesture ? 'long press ' : ''}$label',
          long: gesture,
        );
      }
    }
    return null;
  }

  String _screenSignature() {
    final route = _top;
    if (route == null) return '?';
    final name = route.settings.name;
    if (name != null) return name;
    if (route is ModalRoute) {
      final ctx = route.subtreeContext;
      if (ctx != null) {
        // The first widget under the route's page that is from the app.
        String? type;
        void visit(Element e) {
          if (type != null) return;
          final t = e.widget.runtimeType.toString();
          if (_appScreen.hasMatch(t)) {
            type = t;
            return;
          }
          e.visitChildElements(visit);
        }

        (ctx as Element).visitChildElements(visit);
        if (type != null) return type!;
      }
    }
    return route.runtimeType.toString();
  }

  static final RegExp _appScreen = RegExp(r'(Page|Screen|Sheet|Dialog|Shell)$');

  static bool _isTappable(Widget w) =>
      (w is InkResponse && (w.onTap != null || w.onLongPress != null)) ||
      (w is PopupMenuButton);

  bool _insideExcluded(Element element) {
    var excluded = false;
    element.visitAncestorElements((a) {
      final w = a.widget;
      if (w is NavigationBar ||
          w is NavigationRail ||
          w is BackButton ||
          w is CloseButton ||
          w is EditableText ||
          w is PopupMenuButton && !identical(a, element)) {
        excluded = true;
        return false;
      }
      return true;
    });
    return excluded;
  }

  /// Text, tooltip, semantics label or icon under [element].
  String _labelOf(Element element) {
    final parts = <String>[];
    void visit(Element e) {
      final w = e.widget;
      if (w is Text) {
        final t = w.data ?? w.textSpan?.toPlainText() ?? '';
        if (t.trim().isNotEmpty) parts.add(t.trim());
      } else if (w is Tooltip && w.message != null) {
        parts.add(w.message!);
      } else if (w is Icon && w.icon != null) {
        parts.add('icon:${w.icon!.codePoint.toRadixString(16)}');
      }
      if (parts.length < 3) e.visitChildElements(visit);
    }

    visit(element);
    final key = element.widget.key;
    if (key is ValueKey) parts.insert(0, 'key:${key.value}');
    final label = parts.take(3).join(' / ');
    return label.length > 80 ? label.substring(0, 80) : label;
  }

  String _describe(FlutterErrorDetails details) {
    final text = details.toString();
    final where = RegExp(
      r'(package:ditmesh\S*|package:morse_io\S*|file://\S*/lib/\S*)\.dart:\d+:\d+',
    ).allMatches(text).map((m) => m.group(0)!.split('/lib/').last).toSet();
    return '[$scene] ${_firstLine(details.exceptionAsString())}'
        '${where.isEmpty ? '' : ' @ ${where.take(3).join(', ')}'}';
  }

  static String _firstLine(String s) {
    final line = s.trim().split('\n').first;
    return line.length > 200 ? line.substring(0, 200) : line;
  }
}
