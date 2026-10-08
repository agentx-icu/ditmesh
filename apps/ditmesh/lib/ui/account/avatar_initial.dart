import 'package:flutter/widgets.dart' show Characters, StringCharacters;

/// The letter shown in a name-initial avatar: the first user-perceived
/// character (grapheme cluster) of [name], upper-cased, ignoring leading
/// whitespace; `?` when the name is blank.
///
/// Grapheme-aware on purpose: display names come from the Tox network as
/// arbitrary UTF-8, and `String.substring(0, 1)` would split an emoji's
/// surrogate pair (or a flag / skin-tone cluster) into malformed UTF-16.
String avatarInitial(String name) {
  final Characters chars = name.trimLeft().characters;
  return chars.isEmpty ? '?' : chars.first.toUpperCase();
}
