import 'dart:math' as math;

/// Engineering notation with three significant digits and an SI prefix
/// from pico to giga: `448 pF`, `0.560 µH`, `292 Ω`, `1.50 kΩ`,
/// `5.03 MHz`. Negative values keep their sign.
String formatEngineering(double value, String unit) {
  if (value.isNaN) return '– $unit';
  if (value.isInfinite) return '${value.isNegative ? '-' : ''}∞ $unit';
  if (value == 0) return '0 $unit';
  const prefixes = <int, String>{
    -4: 'p',
    -3: 'n',
    -2: 'µ',
    -1: 'm',
    0: '',
    1: 'k',
    2: 'M',
    3: 'G',
  };
  var exponent = (math.log(value.abs()) / math.ln10 / 3).floor();
  var mantissa = value / math.pow(10, 3 * exponent);
  if (double.parse(mantissa.abs().toStringAsPrecision(3)) >= 1000) {
    exponent += 1;
    mantissa /= 1000;
  }
  exponent = exponent.clamp(-4, 3);
  mantissa = value / math.pow(10, 3 * exponent);
  return '${threeSignificant(mantissa)} ${prefixes[exponent]}$unit';
}

/// Three significant digits: `1.50`, `12.6`, `100`, `-50.0`.
String threeSignificant(double v) {
  final r = double.parse(v.toStringAsPrecision(3));
  final a = r.abs();
  if (a >= 100) return r.toStringAsFixed(0);
  if (a >= 10) return r.toStringAsFixed(1);
  return r.toStringAsFixed(2);
}

/// Ohms with a prefix: `17.6 Ω`, `1.50 kΩ`.
String formatOhms(double ohms) => formatEngineering(ohms, 'Ω');

/// `41.2 km`; whole kilometres from 100 up.
String formatKm(double km) =>
    km >= 100 ? '${km.round()} km' : '${km.toStringAsFixed(1)} km';
