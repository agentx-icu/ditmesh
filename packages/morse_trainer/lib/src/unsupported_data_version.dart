/// A newer application owns this document; callers must preserve it verbatim.
final class UnsupportedDataVersion extends FormatException {
  const UnsupportedDataVersion(String document, num version)
    : super('$document was written by a newer application (version $version)');

  static void check(
    Object? value, {
    required int supported,
    required String document,
  }) {
    if (value is num && value > supported) {
      throw UnsupportedDataVersion(document, value);
    }
  }
}
