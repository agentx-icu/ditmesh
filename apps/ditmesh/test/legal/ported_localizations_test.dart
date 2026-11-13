import 'package:ditmesh/l10n/generated/s.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _strings(S s) => [
  s.accountSectionPrivacy,
  s.accountPersonalInfoList,
  s.accountThirdPartyShareList,
  s.accountPermissionList,
  s.privacyConsentTitle,
  s.privacyConsentSummary,
  s.privacyConsentAccept,
  s.privacyConsentDecline,
  s.privacyConsentSaving,
  s.privacyConsentSaveFailed,
  s.listenMicPurposeTitle,
  s.listenMicPurposeBody,
  s.listenMicPurposeContinue,
  s.personalInfoListText,
  s.thirdPartyShareText,
  s.permissionListText,
  s.technicalSupportText,
  s.legalDocumentUnavailable,
];

void main() {
  final english = _strings(lookupS(const Locale('en')));
  for (final locale in S.supportedLocales) {
    test('privacy and microphone strings are localized for $locale', () {
      final strings = _strings(lookupS(locale));
      for (final (index, value) in strings.indexed) {
        expect(value.trim(), isNotEmpty);
        expect(value, isNot(contains('MorseCQ')));
        if (locale.languageCode != 'en') {
          expect(
            value,
            isNot(english[index]),
            reason: 'Message at index $index',
          );
        }
      }
    });
  }
}
