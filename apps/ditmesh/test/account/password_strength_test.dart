import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/account_widgets.dart';
import 'package:ditmesh/ui/account/password_strength.dart';

void main() {
  test('ratePassword buckets by length and character classes', () {
    expect(ratePassword(''), PasswordStrength.empty);
    expect(ratePassword('short'), PasswordStrength.weak);
    expect(ratePassword('1234567'), PasswordStrength.weak);
    expect(ratePassword('12345678'), PasswordStrength.fair);
    expect(ratePassword('correct horse'), PasswordStrength.fair);
    expect(ratePassword('Correct-horse-9'), PasswordStrength.strong);
    expect(ratePassword('abcdefghijklmnop'), PasswordStrength.fair);
  });

  test('labels exist for every non-empty bucket, in every locale', () {
    for (final locale in S.supportedLocales) {
      final s = lookupS(locale);
      for (final strength in PasswordStrength.values) {
        expect(
          strength.label(s).isEmpty,
          strength == PasswordStrength.empty,
          reason: '$strength in $locale',
        );
      }
    }
  });

  test('groupToxId splits into 4-char groups', () {
    expect(groupToxId('ABCDEFGHIJ'), 'ABCD EFGH IJ');
    expect(groupToxId(''), '');
  });
}
