import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/chat_error_messages.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../learn/helpers/l10n.dart';

void main() {
  test('every contract code maps to its own string', () {
    expect(chatErrorMessage(en, 'wrong_password'), en.errorWrongPassword);
    expect(chatErrorMessage(en, 'peer_offline'), en.errorPeerOffline);
    expect(chatErrorMessage(en, 'invalid_tox_id'), en.errorInvalidToxId);
    expect(chatErrorMessage(en, 'already_friend'), en.errorAlreadyFriend);
    expect(chatErrorMessage(en, 'own_id'), en.errorOwnId);
    expect(chatErrorMessage(en, 'group_not_found'), en.errorGroupNotFound);
    expect(chatErrorMessage(en, 'message_too_long'), en.errorMessageTooLong);
  });

  test('unknown codes fall back to the generic error', () {
    expect(chatErrorMessage(en, 'no_such_code_ever'), en.errorUnknown);
    expect(chatErrorMessage(en, ''), en.errorUnknown);
  });

  test('describeChatError maps exceptions by code, anything else generically', () {
    expect(
      describeChatError(en, const ChatException('own_id', 'that is you')),
      en.errorOwnId,
    );
    expect(
      describeChatError(en, const ChatException('weird', 'x')),
      en.errorUnknown,
    );
    expect(describeChatError(en, StateError('boom')), en.errorUnknown);
    expect(describeChatError(en, 'a string'), en.errorUnknown);
  });

  test('the mapped strings are distinct and translated everywhere', () {
    const List<String> codes = <String>[
      'wrong_password',
      'peer_offline',
      'invalid_tox_id',
      'already_friend',
      'own_id',
      'group_not_found',
      'message_too_long',
    ];
    for (final Locale locale in S.supportedLocales) {
      final S s = lookupS(locale);
      final List<String> texts = <String>[
        for (final String code in codes) chatErrorMessage(s, code),
      ];
      expect(texts.toSet(), hasLength(codes.length), reason: '$locale');
      expect(texts, isNot(contains(s.errorUnknown)), reason: '$locale');
      expect(texts.every((t) => t.trim().isNotEmpty), isTrue, reason: '$locale');
    }
  });
}
