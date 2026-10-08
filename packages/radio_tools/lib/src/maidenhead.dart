import 'geo.dart';

/// The square a Maidenhead locator names: its south-west corner and size.
final class LocatorArea {
  const LocatorArea({
    required this.south,
    required this.west,
    required this.heightDeg,
    required this.widthDeg,
  });

  final double south;
  final double west;
  final double heightDeg;
  final double widthDeg;

  double get north => south + heightDeg;
  double get east => west + widthDeg;

  /// Centre of the square - the conventional point for distance maths.
  GeoPoint get center => GeoPoint(south + heightDeg / 2, west + widthDeg / 2);

  bool contains(GeoPoint p) =>
      p.latitude >= south &&
      p.latitude < north &&
      p.longitude >= west &&
      p.longitude < east;

  @override
  String toString() => 'LocatorArea($south..$north, $west..$east)';
}

/// Maidenhead (QTH) locators: `JO65`, `OM89ex`, `PM95vq42`.
///
/// Pairs, from coarse to fine: field `A`-`R` (20 deg x 10 deg), square
/// `0`-`9` (2 x 1), subsquare `a`-`x` (5' x 2.5'), extended square `0`-`9`
/// (30" x 15"). Longitude always comes first in each pair. Fields are
/// written in upper case and subsquares in lower case; parsing accepts both.
abstract final class Maidenhead {
  /// Valid lengths: 2, 4, 6 or 8 characters.
  static const List<int> lengths = <int>[2, 4, 6, 8];

  static final RegExp _pattern = RegExp(
    r'^[A-R]{2}(?:[0-9]{2}(?:[A-X]{2}(?:[0-9]{2})?)?)?$',
    caseSensitive: false,
  );

  static const List<int> _bases = <int>[18, 10, 24, 10];

  /// Extended squares per step of each pair (product of the finer bases).
  static const List<int> _unitsPerStep = <int>[2400, 240, 10, 1];

  static const int _unitsPerAxis = 43200;

  static int _units(double scaled) =>
      (scaled + 1e-7).floor().clamp(0, _unitsPerAxis - 1);

  /// Whether [locator] is a well-formed 2/4/6/8-character locator.
  static bool isValid(String locator) => _pattern.hasMatch(locator.trim());

  /// Canonical spelling: field upper case, subsquare lower case.
  static String normalize(String locator) {
    final l = locator.trim();
    if (!isValid(l)) {
      throw FormatException('Not a Maidenhead locator', locator);
    }
    if (l.length <= 4) return l.toUpperCase();
    return l.substring(0, 4).toUpperCase() +
        l.substring(4, 6).toLowerCase() +
        l.substring(6);
  }

  /// Locator of [point] with [length] characters (2, 4, 6 or 8).
  static String fromPoint(GeoPoint point, {int length = 6}) {
    if (!lengths.contains(length)) {
      throw ArgumentError.value(length, 'length', 'must be 2, 4, 6 or 8');
    }
    if (!point.isValid) {
      throw ArgumentError.value(point, 'point', 'out of range');
    }
    // Quantise once to whole extended squares (30" x 15", 43200 per axis)
    // and split that integer; subtracting float steps pair by pair drifts
    // across internal edges (0.1 deg E landed in the square west of it).
    // The epsilon absorbs representation error such as 180.1 * 120 =
    // 21611.999...; the east / north world edges belong to the last square.
    final x = _units((point.longitude + 180) * 120);
    final y = _units((point.latitude + 90) * 240);
    final out = StringBuffer();
    for (var pair = 0; pair < length ~/ 2; pair++) {
      final size = _unitsPerStep[pair];
      out
        ..write(_symbol(pair, (x ~/ size) % _bases[pair]))
        ..write(_symbol(pair, (y ~/ size) % _bases[pair]));
    }
    return out.toString();
  }

  /// The square [locator] names. Throws [FormatException] when invalid.
  static LocatorArea toArea(String locator) {
    final l = normalize(locator).toUpperCase();
    var x = 0;
    var y = 0;
    var size = _unitsPerAxis;
    for (var pair = 0; pair < l.length ~/ 2; pair++) {
      size = _unitsPerStep[pair];
      x += _value(pair, l[pair * 2]) * size;
      y += _value(pair, l[pair * 2 + 1]) * size;
    }
    return LocatorArea(
      south: y / 240 - 90,
      west: x / 120 - 180,
      heightDeg: size / 240,
      widthDeg: size / 120,
    );
  }

  /// Centre of [locator]'s square.
  static GeoPoint toPoint(String locator) => toArea(locator).center;

  static String _symbol(int pair, int value) => switch (pair) {
    0 => String.fromCharCode(0x41 + value), // A..R
    2 => String.fromCharCode(0x61 + value), // a..x
    _ => '$value',
  };

  static int _value(int pair, String ch) =>
      pair.isEven ? ch.codeUnitAt(0) - 0x41 : int.parse(ch);
}
