import 'dart:convert';

import 'peer_text.dart';

/// A single position shared as Toxee's interoperable text envelope. The
/// conversation timestamp describes when it was sent; this is not live tracking.
final class ChatLocation {
  const ChatLocation({
    required this.latitude,
    required this.longitude,
    this.description = '',
  });

  static const prefix = '__location__:';
  static const maxWireBytes = 1322;
  final double latitude;
  final double longitude;
  final String description;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  String encode() {
    if (!isValid) throw ArgumentError('Invalid location coordinates');
    final wire =
        '$prefix${jsonEncode({'desc': PeerText.singleLine(description), 'longitude': longitude, 'latitude': latitude})}';
    if (utf8.encode(wire).length > maxWireBytes) {
      throw ArgumentError('Location exceeds the single-message budget');
    }
    return wire;
  }

  static ChatLocation? tryDecode(String wire) {
    if (!wire.startsWith(prefix) ||
        wire.length > maxWireBytes ||
        utf8.encode(wire).length > maxWireBytes) {
      return null;
    }
    try {
      final value = jsonDecode(wire.substring(prefix.length));
      if (value is! Map<String, dynamic>) return null;
      final lat = value['latitude'];
      final lon = value['longitude'];
      final desc = value['desc'];
      if (lat is! num || lon is! num || (desc != null && desc is! String)) {
        return null;
      }
      final location = ChatLocation(
        latitude: lat.toDouble(),
        longitude: lon.toDouble(),
        description: PeerText.singleLine(desc as String? ?? ''),
      );
      return location.isValid ? location : null;
    } on FormatException {
      return null;
    }
  }
}
