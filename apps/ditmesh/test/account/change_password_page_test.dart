import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/change_password_page.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

import 'test_app.dart';

final S s = lookupS(const Locale('en'));

/// Forwards to a [FakeIdentityService] but can fail [changePassword] with
/// something other than a [ChatException].
final class _Failing implements IdentityService {
  _Failing(this.inner);
  final FakeIdentityService inner;
  Object? error;
  @override
  Future<void> changePassword({String? oldPassword, String? newPassword}) {
    final e = error;
    if (e != null) throw e;
    return inner.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    IdentityService service, {
    required bool hasPassword,
  }) async {
    await tester.pumpWidget(
      Provider<IdentityService>.value(
        value: service,
        child: MaterialApp(
          theme: DitmeshTheme.light(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ChangePasswordPage(hasPassword: hasPassword),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('setting a first password validates both fields', (tester) async {
    final service = freshIdentityService();
    addTearDown(service.dispose);
    await service.create(displayName: 'Ann');
    await pump(tester, service, hasPassword: false);

    expect(find.text(s.accountSetPassword), findsOneWidget);
    expect(field(s.accountCurrentPassword), findsNothing);
    expect(find.text(s.accountRemovePassword), findsNothing);

    await tapText(tester, s.actionSave);
    expect(find.text(s.accountNewPasswordRequired), findsOneWidget);
    expect(find.byType(ChangePasswordPage), findsOneWidget);

    await type(tester, s.accountNewPassword, 'hunter22');
    await type(tester, s.accountConfirmPassword, 'hunter23');
    await tapText(tester, s.actionSave);
    expect(find.text(s.accountNewPasswordRequired), findsNothing);
    expect(find.text(s.accountPasswordsDoNotMatch), findsOneWidget);
    expect(service.storedPassword, isNull);

    await type(tester, s.accountConfirmPassword, 'hunter22');
    // Submitting the last field saves too.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(service.storedPassword, 'hunter22');
    expect(service.current!.hasPassword, isTrue);
    expect(find.byType(ChangePasswordPage), findsNothing);
    expect(find.text(s.accountPasswordUpdated), findsOneWidget);
  });

  testWidgets('a wrong current password is shown on that field', (
    tester,
  ) async {
    final service = seededIdentityService(password: 'old');
    addTearDown(service.dispose);
    await service.unlock('old');
    await pump(tester, service, hasPassword: true);

    expect(find.text(s.accountChangePassword), findsOneWidget);
    await type(tester, s.accountCurrentPassword, 'nope');
    await type(tester, s.accountNewPassword, 'new-pass');
    await type(tester, s.accountConfirmPassword, 'new-pass');
    await tapText(tester, s.actionSave);
    final current = tester.widget<TextField>(field(s.accountCurrentPassword));
    expect(current.decoration!.errorText, isNotNull);
    expect(service.storedPassword, 'old');
    expect(find.byType(ChangePasswordPage), findsOneWidget);

    await type(tester, s.accountCurrentPassword, 'old');
    await tapText(tester, s.actionSave);
    expect(service.storedPassword, 'new-pass');
    expect(find.byType(ChangePasswordPage), findsNothing);
  });

  testWidgets('remove needs only the current password', (tester) async {
    final service = seededIdentityService(password: 'old');
    addTearDown(service.dispose);
    await service.unlock('old');
    await pump(tester, service, hasPassword: true);

    await type(tester, s.accountCurrentPassword, 'old');
    await tapText(tester, s.accountRemovePassword);
    expect(service.storedPassword, isNull);
    expect(service.current!.hasPassword, isFalse);
    expect(find.text(s.accountPasswordRemoved), findsOneWidget);
  });

  testWidgets('any other failure lands on the new-password field and the '
      'page stays usable', (tester) async {
    final inner = freshIdentityService();
    addTearDown(inner.dispose);
    await inner.create(displayName: 'Ann');
    final service = _Failing(inner)..error = StateError('keychain locked');
    await pump(tester, service, hasPassword: false);

    await type(tester, s.accountNewPassword, 'pass-1');
    await type(tester, s.accountConfirmPassword, 'pass-1');
    await tapText(tester, s.actionSave);
    final next = tester.widget<TextField>(field(s.accountNewPassword));
    expect(next.decoration!.errorText, isNotNull);
    expect(find.byType(ChangePasswordPage), findsOneWidget);

    service.error = const ChatException('io', 'disk full');
    await tapText(tester, s.actionSave);
    expect(
      tester
          .widget<TextField>(field(s.accountNewPassword))
          .decoration!
          .errorText,
      isNotNull,
    );

    service.error = null;
    await tapText(tester, s.actionSave);
    expect(inner.storedPassword, 'pass-1');
    expect(find.byType(ChangePasswordPage), findsNothing);
  });
}
