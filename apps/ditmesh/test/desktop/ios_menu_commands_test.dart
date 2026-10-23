import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ditmesh/desktop/ios_menu_commands.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/startup/startup_controller.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/moderation/terms_gate_page.dart';

import '../account/test_app.dart';

const _channel = MethodChannel(IosMenuCommands.channelName);
const _codec = StandardMethodCodec();

Future<Object?> _invoke(WidgetTester tester, Object? command) async {
  final reply = await tester.binding.defaultBinaryMessenger
      .handlePlatformMessage(
        IosMenuCommands.channelName,
        _codec.encodeMethodCall(MethodCall('invoke', command)),
        null,
      );
  return reply == null ? null : _codec.decodeEnvelope(reply);
}

List<Map<Object?, Object?>> _record(WidgetTester tester) {
  final states = <Map<Object?, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
    call,
  ) async {
    expect(call.method, 'update');
    states.add(call.arguments as Map<Object?, Object?>);
    return true;
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _channel,
      null,
    ),
  );
  return states;
}

Future<void> _ready(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await pumpApp(tester, identity: seededIdentityService(), size: kDesktopSize);
}

void main() {
  void iosTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(
        name,
        body,
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );

  iosTest('native menu invokes existing search and Contacts only', (
    tester,
  ) async {
    final states = _record(tester);
    await _ready(tester);
    expect(states.last, {
      'title': 'Chat',
      'search': 'Search conversations',
      'contacts': 'Contacts',
      'enabled': true,
    });
    expect(await _invoke(tester, 'sideTone'), isFalse);
    expect(await _invoke(tester, {'command': 'contacts'}), isFalse);
    expect(await _invoke(tester, 'search'), isTrue);
    await settle(tester);
    final search = tester.widget<SearchBar>(find.byType(SearchBar));
    expect(search.focusNode!.hasFocus, isTrue);
    expect(states.last['enabled'], isFalse);
    expect(await _invoke(tester, 'contacts'), isFalse);
    expect(find.byType(ContactsPage), findsNothing);
    // Leaving the editor via an existing navigation control restores commands.
    await tester.tap(find.byIcon(Icons.groups_outlined).first);
    await settle(tester);
    expect(states.last['enabled'], isTrue);
    expect(await _invoke(tester, 'contacts'), isTrue);
    await settle(tester);
    expect(find.byType(ContactsPage, skipOffstage: false), findsOneWidget);
    expect(states.last['enabled'], isFalse);
    expect(await _invoke(tester, 'contacts'), isFalse);
    expect(await _invoke(tester, 'search'), isFalse);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(ConversationList), findsOneWidget);
    expect(states.last['enabled'], isTrue);
  });

  iosTest('locked startup keeps localized menu visible and disabled', (
    tester,
  ) async {
    final states = _record(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpApp(
      tester,
      identity: seededIdentityService(),
      termsAccepted: false,
    );
    expect(find.byType(TermsGatePage), findsOneWidget);
    expect(states.last['search'], 'Search conversations');
    expect(states.last['contacts'], 'Contacts');
    expect(states.last['enabled'], isFalse);
    expect(await _invoke(tester, 'contacts'), isFalse);
    expect(find.byType(ContactsPage), findsNothing);
  });

  iosTest(
    'editor composition, inactive and teardown reject stale native invocation',
    (tester) async {
      final states = _record(tester);
      await _ready(tester);
      await tester.tap(find.byType(SearchBar));
      await tester.pump();
      const value = TextEditingValue(
        text: 'ni',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      tester.testTextInput.updateEditingValue(value);
      await settle(tester);
      expect(await _invoke(tester, 'contacts'), isFalse);
      expect(
        tester.widget<SearchBar>(find.byType(SearchBar)).controller!.value,
        value,
      );
      await tester.tap(find.byIcon(Icons.groups_outlined).first);
      await settle(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(await _invoke(tester, 'contacts'), isFalse);
      await settle(tester);
      expect(states.last['enabled'], isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(states.last['enabled'], isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(states.last['enabled'], isFalse);
      expect(await _invoke(tester, 'contacts'), isNull);
    },
  );

  iosTest(
    'menu uses existing locale labels and updates without re-registration',
    (tester) async {
      final states = _record(tester);
      await _ready(tester);
      final context = tester.element(find.byType(ConversationList));
      await context.read<LocaleController>().setLocale(const Locale('zh'));
      await settle(tester);
      expect(states.last, {
        'title': '聊天',
        'search': '搜索会话',
        'contacts': '联系人',
        'enabled': true,
      });
    },
  );

  iosTest(
    'leaving ready rejects a command before the outgoing shell disposes',
    (tester) async {
      final states = _record(tester);
      await _ready(tester);
      final context = tester.element(find.byType(ConversationList));
      await context.read<StartupController>().deleteIdentity();
      // AnimatedSwitcher can retain the old shell briefly; an owner alone does
      // not establish that the identity/startup gate still allows chat.
      expect(await _invoke(tester, 'contacts'), isFalse);
      await settle(tester);
      expect(states.last['enabled'], isFalse);
      expect(find.byType(ContactsPage, skipOffstage: false), findsNothing);
    },
  );

  testWidgets(
    'disposing an older command owner does not unbind its replacement',
    (tester) async {
      _record(tester);
      var count = 0;
      final commands = IosMenuCommands(canInvoke: () => true, onChanged: () {});
      final old = Object(), current = Object();
      commands.bind(old, search: () => count += 100, contacts: () {});
      commands.bind(current, search: () => count++, contacts: () {});
      commands.unbind(old);
      expect(await _invoke(tester, 'search'), isTrue);
      expect(count, 1);
      commands.unbind(current);
      expect(await _invoke(tester, 'search'), isFalse);
      await commands.dispose();
    },
  );

  testWidgets('an outgoing host cannot clear a newer host channel handler', (
    tester,
  ) async {
    _record(tester);
    var count = 0;
    final older = IosMenuCommands(canInvoke: () => true, onChanged: () {});
    final newer = IosMenuCommands(canInvoke: () => true, onChanged: () {});
    newer.bind(Object(), search: () => count++, contacts: () {});
    await older.dispose();
    expect(await _invoke(tester, 'search'), isTrue);
    expect(count, 1);
    await newer.dispose();
  });
}
