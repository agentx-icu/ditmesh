import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/network/bootstrap_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Checklist N10: the network pages on a 320 px phone (2x device pixel ratio)
/// at 2x text with the node strings that stretch them: a long host name, a
/// bracketed IPv6 literal with an IPv4 alternate, 64-hex public keys, a long
/// maintainer label and several TCP ports.
const _longHost = BootstrapNode(
  host:
      'tox-bootstrap.very-long-operator-name.infrastructure.example-network.org',
  port: 33445,
  publicKey: '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
  udpOnline: true,
  tcpOnline: true,
  tcpPorts: [443, 3389, 33445],
  maintainer: 'An operator whose display name does not fit one phone line',
  location: 'DE',
);
const _ipv6 = BootstrapNode(
  host: '2600:3c03:0000:0000:f03c:93ff:fe7f:6096',
  port: 33445,
  publicKey: '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674',
  alternateHosts: ['172.104.215.182'],
  udpOnline: true,
  tcpOnline: true,
  tcpPorts: [443, 33445],
  maintainer: 'zero-one',
  location: 'US',
);
const _ipv6Endpoint = '[2600:3c03:0000:0000:f03c:93ff:fe7f:6096]:33445';

Future<void> _pumpPhone(
  WidgetTester tester,
  FakeNetworkBootstrapService service, {
  String language = 'en',
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(640, 2000); // 320 x 1000 logical
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(service.dispose);
  await tester.pumpWidget(
    Provider<NetworkBootstrapService?>.value(
      value: service,
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const BootstrapPage(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
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

void main() {
  for (final language in ['en', 'de', 'ru']) {
    testWidgets('node list fits 320 px at 2x text, long host and IPv6 literal '
        '($language)', (tester) async {
      final service = FakeNetworkBootstrapService(supportsLan: false)
        ..catalogue = const BootstrapCatalogue(
          nodes: [_longHost, _ipv6],
          fromFallback: false,
        );
      await _pumpPhone(tester, service, language: language);
      await _tap(tester, 'bootstrap-open-nodes');
      expect(find.text(_longHost.endpoint), findsOneWidget);
      // The list is lazy: the second card is below the fold at this size.
      await tester.scrollUntilVisible(
        find.text(_ipv6Endpoint),
        200,
        // The selectable node texts carry Scrollables of their own.
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(_ipv6Endpoint), findsOneWidget);
      expect(find.text('172.104.215.182'), findsOneWidget);
      // Every action of the last card is still reachable and tappable.
      await _tap(tester, 'bootstrap-node-test-${_ipv6.id}');
      expect(service.probed, [_ipv6]);
      await _tap(tester, 'bootstrap-node-select-${_ipv6.id}');
      // The confirmation names the bracketed endpoint.
      expect(find.textContaining(_ipv6Endpoint), findsWidgets);
      await _tap(tester, 'bootstrap-switch-confirm');
      expect(service.configuration.current, _ipv6);
      // Back on the settings page, the current-node card shows it.
      expect(find.text(_ipv6Endpoint), findsOneWidget);
      expect(find.text(_ipv6.publicKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('current node and manual form fit 320 px at 2x text (IPv6)', (
    tester,
  ) async {
    final service = FakeNetworkBootstrapService(supportsLan: false);
    await service.selectNode(_ipv6);
    await service.setMode(BootstrapMode.manual);
    await _pumpPhone(tester, service);
    expect(find.text(_ipv6Endpoint), findsOneWidget);
    // Once in the card (selectable) and once in the manual form's field.
    expect(
      find.widgetWithText(SelectableText, _ipv6.publicKey),
      findsOneWidget,
    );
    // The manual form edits the bare address, as NETWORK.md says.
    final host = tester.widget<TextField>(
      find.byKey(const ValueKey('bootstrap-manual-host')),
    );
    expect(host.controller!.text, _ipv6.host);
    await _tap(tester, 'bootstrap-current-test');
    expect(service.probed, [_ipv6]);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
