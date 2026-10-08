// String.characters comes with the widgets library (package:characters).
import 'package:flutter/widgets.dart';

/// A decoder token at the end of the draft: a prosign (`<SK>`) or a
/// pattern it could not read (`<..--.>`). Composer rule, not the encoder's:
/// the decoder appends either as one unit, so delete-last removes either
/// whole.
final RegExp _trailingToken = RegExp(r'<[^<>\s]+>$');

/// [text] without its last keyed unit: a trailing `<...>` token, else the
/// last user-perceived character (never half a surrogate pair or an emoji
/// sequence). Stateless, so a draft restored from storage or shared with
/// another route deletes the same way as one keyed here.
String withoutLastKeyedUnit(String text) {
  if (text.isEmpty) return text;
  final Match? token = _trailingToken.firstMatch(text);
  if (token != null) return text.substring(0, token.start);
  return text.characters.skipLast(1).toString();
}
