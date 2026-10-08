import 'dart:async';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';
import 'package:ditmesh/ui/network/bootstrap_page.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/account/unlock_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _key = '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C';
const _node = BootstrapNode(
  host: '192.0.2.1',
  port: 33445,
  publicKey: _key,
  udpOnline: true,
  maintainer: 'Test operator',
  location: 'CA',
);

Future<void> _pump(
  WidgetTester tester,
  FakeNetworkBootstrapService service, {
  double width = 430,
  String language = 'en',
  Widget home = const BootstrapPage(),
  double textScale = 1,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(service.dispose);
  await tester.pumpWidget(
    Provider<NetworkBootstrapService?>.value(
      value: service,
      child: MaterialApp(
        locale: parseLocaleTag(language),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: direction ?? Directionality.of(context),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _DelayedNetwork extends FakeNetworkBootstrapService {
  _DelayedNetwork() : super(supportsLan: false);
  final result = Completer<BootstrapProbeVerdict>();
  @override
  Future<BootstrapProbeVerdict> probe(BootstrapNode node) => result.future;
}

void main() {
  testWidgets(
    'mobile exposes auto and manual and tests before identity exists',
    (tester) async {
      final service = FakeNetworkBootstrapService(supportsLan: false);
      await _pump(tester, service);
      expect(find.byKey(const ValueKey('bootstrap-mode-lan')), findsNothing);
      await _tap(tester, 'bootstrap-mode-manual');
      await tester.enterText(
        find.byKey(const ValueKey('bootstrap-manual-host')),
        _node.host,
      );
      await tester.enterText(
        find.byKey(const ValueKey('bootstrap-manual-key')),
        _key,
      );
      await _tap(tester, 'bootstrap-manual-test');
      expect(service.probed.single.host, _node.host);
      await _tap(tester, 'bootstrap-manual-save');
      expect(service.configuration.current?.host, _node.host);
    },
  );

  testWidgets('editing a tested manual tuple disables promotion', (
    tester,
  ) async {
    final service = FakeNetworkBootstrapService(supportsLan: false);
    await _pump(tester, service);
    await _tap(tester, 'bootstrap-mode-manual');
    await tester.enterText(
      find.byKey(const ValueKey('bootstrap-manual-host')),
      _node.host,
    );
    await tester.enterText(
      find.byKey(const ValueKey('bootstrap-manual-key')),
      _key,
    );
    await _tap(tester, 'bootstrap-manual-test');
    await tester.enterText(
      find.byKey(const ValueKey('bootstrap-manual-host')),
      '192.0.2.2',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('bootstrap-manual-save')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'catalogue exposes independent test and switch actions and fallback',
    (tester) async {
      final service = FakeNetworkBootstrapService(supportsLan: false)
        ..catalogue = const BootstrapCatalogue(
          nodes: [_node],
          fromFallback: true,
        );
      await _pump(tester, service);
      await _tap(tester, 'bootstrap-open-nodes');
      expect(
        find.byKey(const ValueKey('bootstrap-list-fallback')),
        findsOneWidget,
      );
      expect(find.text(_node.endpoint), findsOneWidget);
      await _tap(tester, 'bootstrap-node-test-${_node.id}');
      expect(service.probed, [_node]);
      await _tap(tester, 'bootstrap-node-select-${_node.id}');
      await _tap(tester, 'bootstrap-switch-confirm');
      expect(service.configuration.current, _node);
    },
  );

  testWidgets(
    'catalogue selection updates committed manual fields and invalidates probe',
    (tester) async {
      final service = FakeNetworkBootstrapService(supportsLan: false)
        ..catalogue = const BootstrapCatalogue(
          nodes: [_node],
          fromFallback: false,
        );
      await service.selectNode(
        const BootstrapNode(host: '192.0.2.99', port: 33446, publicKey: _key),
      );
      await service.setMode(BootstrapMode.manual);
      await _pump(tester, service);
      await _tap(tester, 'bootstrap-manual-test');
      await _tap(tester, 'bootstrap-open-nodes');
      await _tap(tester, 'bootstrap-node-select-${_node.id}');
      await _tap(tester, 'bootstrap-switch-confirm');
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('bootstrap-manual-host')),
            )
            .controller!
            .text,
        _node.host,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('bootstrap-manual-port')),
            )
            .controller!
            .text,
        '${_node.port}',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('bootstrap-manual-key')),
            )
            .controller!
            .text,
        _node.publicKey,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('bootstrap-manual-save')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  for (final home in [const WelcomePage(), const UnlockPage()]) {
    testWidgets(
      'network configuration opens before identity via ${home.runtimeType}',
      (tester) async {
        final service = FakeNetworkBootstrapService(supportsLan: false);
        await _pump(tester, service, home: home);
        await _tap(tester, 'onboarding-network-bootstrap');
        expect(find.byType(BootstrapPage), findsOneWidget);
        expect(
          find.byKey(const ValueKey('bootstrap-open-nodes')),
          findsOneWidget,
        );
      },
    );
  }

  for (final verdict in [
    BootstrapProbeVerdict.unreachable,
    BootstrapProbeVerdict.udpUnavailable,
    BootstrapProbeVerdict.unavailable,
  ]) {
    testWidgets(
      'manual probe $verdict distinguishes failure from inconclusive',
      (tester) async {
        final service = FakeNetworkBootstrapService(supportsLan: false)
          ..verdict = verdict;
        await _pump(tester, service);
        await _tap(tester, 'bootstrap-mode-manual');
        await tester.enterText(
          find.byKey(const ValueKey('bootstrap-manual-host')),
          _node.host,
        );
        await tester.enterText(
          find.byKey(const ValueKey('bootstrap-manual-key')),
          _key,
        );
        await _tap(tester, 'bootstrap-manual-test');
        final save = tester.widget<FilledButton>(
          find.byKey(const ValueKey('bootstrap-manual-save')),
        );
        expect(save.onPressed != null, verdict.permitsSelection);
        expect(
          find.byIcon(
            verdict.permitsSelection
                ? Icons.info_outline
                : Icons.cancel_outlined,
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('selection failure keeps the current descriptor and reports it', (
    tester,
  ) async {
    final service = FakeNetworkBootstrapService(supportsLan: false);
    await service.selectNode(_node);
    service.failSelection = true;
    await _pump(tester, service);
    await _tap(tester, 'bootstrap-mode-manual');
    await tester.enterText(
      find.byKey(const ValueKey('bootstrap-manual-host')),
      '192.0.2.2',
    );
    await _tap(tester, 'bootstrap-manual-test');
    await _tap(tester, 'bootstrap-manual-save');
    expect(service.configuration.current, _node);
    final context = tester.element(find.byType(BootstrapPage));
    expect(find.text(S.of(context).bootstrapOperationFailed), findsOneWidget);
  });

  testWidgets(
    'automatic mode tests the saved current node directly at320px and large text',
    (tester) async {
      final service = FakeNetworkBootstrapService(supportsLan: false);
      await service.selectNode(_node);
      await _pump(
        tester,
        service,
        width: 320,
        textScale: 2,
        direction: TextDirection.rtl,
      );
      expect(find.text(_node.publicKey), findsOneWidget);
      await _tap(tester, 'bootstrap-current-test');
      expect(service.probed, [_node]);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('manual mode also tests the saved current node directly', (
    tester,
  ) async {
    final service = FakeNetworkBootstrapService(supportsLan: false);
    await service.selectNode(_node);
    await service.setMode(BootstrapMode.manual);
    await _pump(tester, service);
    await _tap(tester, 'bootstrap-current-test');
    expect(service.probed, [_node]);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('a late current-node result cannot label a new selection', (
    tester,
  ) async {
    final service = _DelayedNetwork();
    await service.selectNode(_node);
    await _pump(tester, service);
    final button = find.byKey(const ValueKey('bootstrap-current-test'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    const next = BootstrapNode(host: '192.0.2.2', port: 33445, publicKey: _key);
    await service.selectNode(next);
    await tester.pump();
    service.result.complete(BootstrapProbeVerdict.reachable);
    await tester.pumpAndSettle();
    expect(find.text(next.endpoint), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop hosts a LAN node with full usable node info', (
    tester,
  ) async {
    final service = FakeNetworkBootstrapService();
    await _pump(tester, service, width: 900);
    await _tap(tester, 'bootstrap-mode-lan');
    await _tap(tester, 'bootstrap-lan-start');
    final node = service.configuration.lanNode!;
    expect(find.text(node.publicKey), findsOneWidget);
    expect(find.text(node.endpoint), findsOneWidget);
    expect(find.byKey(const ValueKey('bootstrap-lan-copy')), findsOneWidget);
    expect(find.byKey(const ValueKey('bootstrap-lan-share')), findsOneWidget);
    await _tap(tester, 'bootstrap-lan-stop');
    expect(service.configuration.lanNode, isNull);
  });

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets('320px large-text manual and catalogue flow in $direction', (
      tester,
    ) async {
      final service = FakeNetworkBootstrapService(supportsLan: false)
        ..catalogue = const BootstrapCatalogue(
          nodes: [_node],
          fromFallback: true,
        );
      await _pump(
        tester,
        service,
        width: 320,
        textScale: 2,
        direction: direction,
        language: 'de',
      );
      await _tap(tester, 'bootstrap-mode-manual');
      await tester.enterText(
        find.byKey(const ValueKey('bootstrap-manual-host')),
        _node.host,
      );
      await tester.enterText(
        find.byKey(const ValueKey('bootstrap-manual-key')),
        _key,
      );
      await _tap(tester, 'bootstrap-manual-test');
      await _tap(tester, 'bootstrap-manual-save');
      expect(service.configuration.current, _node);
      await _tap(tester, 'bootstrap-open-nodes');
      await _tap(tester, 'bootstrap-node-test-${_node.id}');
      await _tap(tester, 'bootstrap-node-select-${_node.id}');
      await _tap(tester, 'bootstrap-switch-confirm');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('popping a page while probing ignores late completion', (
    tester,
  ) async {
    final service = _DelayedNetwork();
    await _pump(tester, service, home: const WelcomePage());
    await _tap(tester, 'onboarding-network-bootstrap');
    await _tap(tester, 'bootstrap-mode-manual');
    await tester.enterText(
      find.byKey(const ValueKey('bootstrap-manual-host')),
      _node.host,
    );
    await tester.enterText(
      find.byKey(const ValueKey('bootstrap-manual-key')),
      _key,
    );
    final button = find.byKey(const ValueKey('bootstrap-manual-test'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    Navigator.of(tester.element(find.byType(BootstrapPage))).pop();
    await tester.pumpAndSettle();
    service.result.complete(BootstrapProbeVerdict.reachable);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in [
    'en',
    'zh',
    'zh_Hant',
    'de',
    'fr',
    'ru',
    'ko',
    'es',
    'pt',
    'ja',
  ]) {
    testWidgets('manual page fits 360 px in $language', (tester) async {
      final service = FakeNetworkBootstrapService(supportsLan: false);
      await _pump(tester, service, width: 360, language: language);
      await _tap(tester, 'bootstrap-mode-manual');
      expect(tester.takeException(), isNull);
    });
  }
}
