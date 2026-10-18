/// One NCDXF / IARU International Beacon Project station.
final class Beacon {
  const Beacon(this.callsign, this.locator);

  final String callsign;

  /// Six-character Maidenhead locator of the transmitter.
  final String locator;

  @override
  String toString() => 'Beacon($callsign $locator)';
}

/// The NCDXF / IARU beacon network: 18 beacons sharing five HF frequencies
/// in a three-minute cycle.
///
/// Each beacon sends for 10 seconds on 14.100 MHz, then steps up through
/// 18.110, 21.150, 24.930 and 28.200 MHz; the next beacon in the list
/// starts on 14.100 MHz as it moves on. A beacon's slot therefore repeats
/// every 3 minutes, and at any moment one beacon is on each frequency.
/// Beacon 0 (4U1UN) starts on 14.100 MHz on the hour and every third
/// minute after it. The transmission is the callsign in CW at 22 WPM, then
/// four one-second dashes at 100 W, 10 W, 1 W and 0.1 W.
abstract final class NcdxfBeacons {
  /// Transmit frequencies, in the order a beacon steps through them.
  static const List<double> frequenciesMhz = <double>[
    14.100,
    18.110,
    21.150,
    24.930,
    28.200,
  ];

  static const Duration slot = Duration(seconds: 10);
  static const Duration cycle = Duration(minutes: 3);

  /// Beacons in transmission order.
  static const List<Beacon> beacons = <Beacon>[
    Beacon('4U1UN', 'FN30as'),
    Beacon('VE8AT', 'CP38gh'),
    Beacon('W6WX', 'CM97bd'),
    Beacon('KH6RS', 'BL10ts'),
    Beacon('ZL6B', 'RE78tw'),
    Beacon('VK6RBP', 'OF87av'),
    Beacon('JA2IGY', 'PM84jk'),
    Beacon('RR9O', 'NO14kx'),
    Beacon('VR2B', 'OL72bg'),
    Beacon('4S7B', 'MJ96wv'),
    Beacon('ZS6DN', 'KG33xi'),
    Beacon('5Z4B', 'KI88hr'),
    Beacon('4X6TU', 'KM72jb'),
    Beacon('OH2B', 'KP20eh'),
    Beacon('CS3B', 'IM12jt'),
    Beacon('LU4AA', 'GF05tj'),
    Beacon('OA4B', 'FH17mw'),
    Beacon('YV5B', 'FK60nd'),
  ];

  /// Seconds since the current cycle began, 0..179.
  static int secondsIntoCycle(DateTime time) {
    final utc = time.toUtc();
    return (utc.minute % 3) * 60 + utc.second;
  }

  /// Index of the 10-second slot [time] falls in, 0..17.
  static int slotIndex(DateTime time) =>
      secondsIntoCycle(time) ~/ slot.inSeconds;

  /// How long the current slot still runs, 1..10 s.
  static Duration slotRemaining(DateTime time) => Duration(
    seconds: slot.inSeconds - secondsIntoCycle(time) % slot.inSeconds,
  );

  /// The beacon transmitting on `frequenciesMhz[band]` at [time].
  ///
  /// Beacon `i` is on band `b` during slot `(i + b) mod 18`.
  static Beacon onAir(DateTime time, int band) {
    RangeError.checkValidIndex(band, frequenciesMhz, 'band');
    return beacons[(slotIndex(time) - band) % beacons.length];
  }

  /// Time until [beacon] next starts on `frequenciesMhz[band]`; zero when
  /// it is starting right now.
  static Duration untilNext(DateTime time, Beacon beacon, {int band = 0}) {
    RangeError.checkValidIndex(band, frequenciesMhz, 'band');
    final i = beacons.indexOf(beacon);
    if (i < 0) {
      throw ArgumentError.value(beacon, 'beacon', 'not an NCDXF beacon');
    }
    final start = ((i + band) % beacons.length) * slot.inSeconds;
    var delta = start - secondsIntoCycle(time);
    if (delta < 0) delta += cycle.inSeconds;
    return Duration(seconds: delta);
  }
}
