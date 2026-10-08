/// Cleaning for text that arrives from other Tox peers (nicknames, group
/// names, friend-request wording, message text) before it is shown or put
/// into an OS notification.
///
/// Removes the characters that let a peer make a label read differently
/// from what it is: the Unicode bidirectional embeddings, overrides and
/// isolates (U+202A–U+202E, U+2066–U+2069), the implicit direction marks
/// (U+200E, U+200F, U+061C), and C0 / C1 control characters other than tab
/// and newline (which [singleLine] turns into spaces for labels).
abstract final class PeerText {
  static final RegExp _unsafe = RegExp(
    '[\u0000-\u0008\u000B-\u001F\u007F-\u009F'
    '\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]',
  );

  /// Tab, LF, and the Unicode line / paragraph separators (U+2028, U+2029),
  /// which Flutter also renders as hard breaks.
  static final RegExp _lineBreaks = RegExp('[\t\n\u2028\u2029]+');

  /// [text] without the unsafe characters; tabs and newlines are kept.
  static String clean(String text) => text.replaceAll(_unsafe, '');

  /// [clean], with tabs, newlines and Unicode line separators folded to
  /// single spaces and the result
  /// trimmed: for names and titles that must stay on one line.
  static String singleLine(String text) =>
      clean(text).replaceAll(_lineBreaks, ' ').trim();
}
