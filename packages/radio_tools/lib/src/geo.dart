import 'dart:math';

/// A position in decimal degrees (WGS-84; north and east positive).
final class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Whether both coordinates are finite and in range.
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// Great-circle maths on a spherical Earth - plenty for amateur distances
/// (the spheroid error is well under 0.5 %).
abstract final class GreatCircle {
  /// IUGG mean Earth radius.
  static const double earthRadiusKm = 6371.0088;

  static const double kmPerMile = 1.609344;

  /// Shortest distance along the surface (haversine), in kilometres.
  static double distanceKm(GeoPoint a, GeoPoint b) {
    final phi1 = _rad(a.latitude);
    final phi2 = _rad(b.latitude);
    final dPhi = phi2 - phi1;
    final dLambda = _rad(b.longitude - a.longitude);
    final h =
        pow(sin(dPhi / 2), 2) +
        cos(phi1) * cos(phi2) * pow(sin(dLambda / 2), 2);
    return 2 * earthRadiusKm * asin(sqrt(min(1.0, h.toDouble())));
  }

  /// Initial bearing (short path) from [from] towards [to], in degrees
  /// clockwise from true north, 0 <= result < 360. Zero for coincident points.
  static double initialBearing(GeoPoint from, GeoPoint to) {
    final phi1 = _rad(from.latitude);
    final phi2 = _rad(to.latitude);
    final dLambda = _rad(to.longitude - from.longitude);
    final y = sin(dLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda);
    if (y.abs() < 1e-12 && x.abs() < 1e-12) {
      return 0;
    }
    final deg = atan2(y, x) * 180 / pi;
    return (deg + 360) % 360;
  }

  /// Long-path bearing: the short-path bearing turned around.
  static double longPathBearing(GeoPoint from, GeoPoint to) =>
      (initialBearing(from, to) + 180) % 360;

  /// Long-path distance: the rest of the great circle.
  static double longPathKm(GeoPoint a, GeoPoint b) =>
      2 * pi * earthRadiusKm - distanceKm(a, b);

  static double _rad(double deg) => deg * pi / 180;
}
