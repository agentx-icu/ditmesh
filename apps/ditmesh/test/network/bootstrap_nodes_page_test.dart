import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/network/bootstrap_nodes_page.dart';
import 'package:ditmesh/ui/network/lan_bootstrap_panel.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final S s = lookupS(const Locale('en'));
const _key = '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C';
const _online = BootstrapNode(
  host: '192.0.2.1',
  port: 33445,
  publicKey: _key,
  alternateHosts: ['2001:db8::1'],
  udpOnline: true,
);
const _offline = BootstrapNode(
  host: '192.0.2.2',
  port: 33445,
  publicKey: _key,
  maintainer: 'op',
  location: 'DE',
);

/// The catalogue page reached from the network settings: test, warn, switch.
class _Network extends FakeNetworkBootstrapService {
  _Network() : super(supportsLan: true);
  Object? loadError;
  Object? probeError;
  Object? lanError;
  int loads = 0;
  @override
  Future<BootstrapCatalogue> loadNodes() async {
    loads++;
    final e = loadError;
    if (e != null) throw e;
    return catalogue;
  }

  @override
  Future<BootstrapProbeVerdict> probe(BootstrapNode node) async {
    final e = probeError;
    if (e != null) throw e;
    return super.probe(node);
  }

  @override
  Future<void> startLan(int port) async {
    final e = lanError;
    if (e != null) throw e;
    return super.startLan(port);
  }
}

Future<_Network> _pumpNodes(
  WidgetTester tester, {
  List<BootstrapNode> nodes = const [_online, _offline],
  bool fallback = false,
  void Function(_Network)? configure,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final service = _Network()
    ..catalogue = BootstrapCatalogue(nodes: nodes, fromFallback: fallback);
  configure?.call(service);
  addTearDown(service.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BootstrapNodesPage(service: service),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return service;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

String _dialogText(WidgetTester tester) => tester
    .widget<Text>(
      find
          .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
          .at(1),
    )
    .data!;

void main() {
  testWidgets('lists every node with its details; offline nodes cannot be '
      'chosen', (tester) async {
    await _pumpNodes(tester, fallback: true);
    expect(
      find.byKey(const ValueKey('bootstrap-list-fallback')),
      findsOneWidget,
    );
    expect(find.text(_online.endpoint), findsOneWidget);
    expect(find.text('2001:db8::1'), findsOneWidget);
    expect(find.text('${s.bootstrapMaintainer}: op'), findsOneWidget);
    expect(find.text('${s.bootstrapLocation}: DE'), findsOneWidget);
    final select = tester.widget<FilledButton>(
      find.byKey(ValueKey('bootstrap-node-select-${_offline.id}')),
    );
    expect(select.onPressed, isNull);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(ValueKey('bootstrap-node-select-${_online.id}')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a catalogue that cannot load says so; refresh retries', (
    tester,
  ) async {
    final service = await _pumpNodes(
      tester,
      configure: (n) => n.loadError = StateError('offline'),
    );
    expect(find.text(s.bootstrapOperationFailed), findsOneWidget);
    service.loadError = null;
    await tester.tap(find.byTooltip(s.bootstrapRefresh));
    await tester.pumpAndSettle();
    expect(service.loads, 2);
    expect(find.text(_online.endpoint), findsOneWidget);
  });

  testWidgets('switching to an untested node warns first; cancel keeps the '
      'current one', (tester) async {
    final service = await _pumpNodes(tester);
    await _tapKey(tester, 'bootstrap-node-select-${_online.id}');
    expect(find.text(s.bootstrapSwitchTitle), findsOneWidget);
    expect(_dialogText(tester), contains(s.bootstrapNotTestedWarning));
    expect(_dialogText(tester), contains(_online.endpoint));
    await tester.tap(find.text(s.actionCancel));
    await tester.pumpAndSettle();
    expect(service.selected, isEmpty);
    expect(find.byType(BootstrapNodesPage), findsOneWidget);
  });

  for (final (verdict, warning) in [
    (BootstrapProbeVerdict.reachable, null),
    (BootstrapProbeVerdict.udpUnavailable, 'inconclusive'),
    (BootstrapProbeVerdict.unreachable, 'failed'),
  ]) {
    testWidgets('a ${verdict.name} probe → ${warning ?? 'no'} warning; '
        'confirm switches and closes', (tester) async {
      final service = await _pumpNodes(
        tester,
        configure: (n) => n.verdict = verdict,
      );
      await _tapKey(tester, 'bootstrap-node-test-${_online.id}');
      expect(service.probed, [_online]);
      await _tapKey(tester, 'bootstrap-node-select-${_online.id}');
      final text = _dialogText(tester);
      expect(text, isNot(contains(s.bootstrapNotTestedWarning)));
      expect(
        text.contains(s.bootstrapInconclusiveWarning),
        warning == 'inconclusive',
      );
      expect(text.contains(s.bootstrapFailedWarning), warning == 'failed');
      await tester.tap(find.byKey(const ValueKey('bootstrap-switch-confirm')));
      await tester.pumpAndSettle();
      expect(service.selected, [_online]);
      expect(service.configuration.current, _online);
      expect(find.byType(BootstrapNodesPage), findsNothing);
    });
  }

  testWidgets('a probe that throws counts as unavailable, not as failed', (
    tester,
  ) async {
    await _pumpNodes(
      tester,
      configure: (n) => n.probeError = StateError('no UDP socket'),
    );
    await _tapKey(tester, 'bootstrap-node-test-${_online.id}');
    expect(find.text(s.bootstrapProbeUnavailable), findsOneWidget);
    await _tapKey(tester, 'bootstrap-node-select-${_online.id}');
    expect(_dialogText(tester), contains(s.bootstrapInconclusiveWarning));
  });

  testWidgets('a failed switch stays on the page and reports it', (
    tester,
  ) async {
    final service = await _pumpNodes(
      tester,
      configure: (n) => n.failSelection = true,
    );
    await _tapKey(tester, 'bootstrap-node-select-${_online.id}');
    await tester.tap(find.byKey(const ValueKey('bootstrap-switch-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(BootstrapNodesPage), findsOneWidget);
    expect(find.text(s.bootstrapOperationFailed), findsOneWidget);
    expect(service.configuration.current, isNull);
    // Not left busy: the node can be tried again.
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(ValueKey('bootstrap-node-select-${_online.id}')),
          )
          .onPressed,
      isNotNull,
    );
  });

  group('LanBootstrapPanel', () {
    Future<_Network> pumpLan(WidgetTester tester) async {
      final service = _Network();
      addTearDown(service.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StreamBuilder<BootstrapConfiguration>(
                stream: service.changes,
                initialData: service.configuration,
                builder: (context, snap) => LanBootstrapPanel(
                  service: service,
                  configuration: snap.data!,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return service;
    }

    FilledButton start(WidgetTester tester) => tester.widget<FilledButton>(
      find.byKey(const ValueKey('bootstrap-lan-start')),
    );

    testWidgets('an out-of-range port cannot start the node', (tester) async {
      await pumpLan(tester);
      expect(find.text(s.bootstrapLanStopped), findsOneWidget);
      expect(start(tester).onPressed, isNotNull);
      for (final bad in ['0', '65536', 'abc', '']) {
        await tester.enterText(find.byType(TextField), bad);
        await tester.pump();
        expect(start(tester).onPressed, isNull, reason: '"$bad"');
      }
    });

    testWidgets('start, copy the descriptor, stop', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final service = await pumpLan(tester);
      await tester.enterText(find.byType(TextField), '40000');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('bootstrap-lan-start')));
      await tester.pumpAndSettle();
      final node = service.configuration.lanNode!;
      expect(node.port, 40000);
      expect(find.text(s.bootstrapLanRunning), findsOneWidget);
      expect(find.text(node.endpoint), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bootstrap-lan-copy')));
      await tester.pumpAndSettle();
      expect(copied, ['${node.host}\n40000\n${node.publicKey}']);

      await tester.tap(find.byKey(const ValueKey('bootstrap-lan-stop')));
      await tester.pumpAndSettle();
      expect(service.configuration.lanNode, isNull);
      expect(find.text(s.bootstrapLanStopped), findsOneWidget);
      // The port field comes back with the port that was used.
      expect(find.text('40000'), findsOneWidget);
    });

    testWidgets('a failed start is reported and the panel recovers', (
      tester,
    ) async {
      final service = await pumpLan(tester);
      service.lanError = StateError('port in use');
      await tester.tap(find.byKey(const ValueKey('bootstrap-lan-start')));
      await tester.pumpAndSettle();
      expect(find.text(s.bootstrapOperationFailed), findsOneWidget);
      expect(find.text(s.bootstrapLanStopped), findsOneWidget);
      expect(start(tester).onPressed, isNotNull);
    });
  });
}
