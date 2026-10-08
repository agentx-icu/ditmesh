import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/message_status_icon.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../learn/helpers/l10n.dart';

Future<void> _pump(WidgetTester tester, MessageStatus status) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    l10nApp(
      theme: DitmeshTheme.light(),
      home: Scaffold(body: Center(child: MessageStatusIcon(status, size: 20))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('received renders nothing', (tester) async {
    await _pump(tester, MessageStatus.received);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('pending explains that nothing is lost', (tester) async {
    await _pump(tester, MessageStatus.pending);
    final Icon icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.schedule);
    expect(icon.size, 20);
    final String tip = tester.widget<Tooltip>(find.byType(Tooltip)).message!;
    expect(tip, contains(en.messageStatusPending));
    expect(tip, contains(en.messageStatusPendingDetail));
    expect(icon.semanticLabel, tip);
  });

  testWidgets('sending, sent and failed each have their glyph', (tester) async {
    final ColorScheme scheme = DitmeshTheme.light().colorScheme;

    await _pump(tester, MessageStatus.sending);
    expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.more_horiz);
    expect(find.byTooltip(en.messageStatusSending), findsOneWidget);

    await _pump(tester, MessageStatus.sent);
    final Icon sent = tester.widget<Icon>(find.byType(Icon));
    expect(sent.icon, Icons.check);
    expect(sent.color, scheme.primary);
    expect(find.byTooltip(en.messageStatusSent), findsOneWidget);

    await _pump(tester, MessageStatus.failed);
    final Icon failed = tester.widget<Icon>(find.byType(Icon));
    expect(failed.icon, Icons.error_outline);
    expect(failed.color, scheme.error);
    expect(find.byTooltip(en.messageStatusFailed), findsOneWidget);
  });
}
