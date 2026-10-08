/// A Tox address ("Tox ID"): 32-byte public key + 4-byte nospam + 2-byte
/// checksum, as 76 hex characters. One definition for the add-friend form,
/// the QR scanner, the Tox backend and the fake, so they all agree on what
/// `invalid_tox_id` means.
abstract final class ToxAddress {
  /// Hex characters in an address.
  static const int length = 76;

  static final RegExp _hex = RegExp(r'^[0-9A-Fa-f]+$');

  /// 76 hex characters whose last two bytes are the checksum: the XOR of the
  /// first 36 bytes taken as 18 two-byte words (toxcore `address_checksum`).
  /// A one-character typo fails here instead of in `tox_friend_add`.
  static bool isValid(String value) {
    if (value.length != length || !_hex.hasMatch(value)) return false;
    final List<int> sum = checksum(value.substring(0, length - 4));
    return sum[0] == int.parse(value.substring(72, 74), radix: 16) &&
        sum[1] == int.parse(value.substring(74, 76), radix: 16);
  }

  /// The two checksum bytes of a 72-hex key + nospam [body].
  static List<int> checksum(String body) {
    var even = 0;
    var odd = 0;
    for (var i = 0; i + 1 < body.length; i += 2) {
      final int byte = int.parse(body.substring(i, i + 2), radix: 16);
      if ((i ~/ 2).isEven) {
        even ^= byte;
      } else {
        odd ^= byte;
      }
    }
    return [even, odd];
  }

  /// [body] (72 hex: key + nospam) with its checksum appended, upper case.
  static String withChecksum(String body) {
    final List<int> sum = checksum(body);
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '$body${hex(sum[0])}${hex(sum[1])}'.toUpperCase();
  }
}
