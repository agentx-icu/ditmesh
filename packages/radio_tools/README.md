[简体中文](./README.zh-CN.md)

# radio_tools

Pure-Dart amateur radio maths behind DitMesh's **Radio tools** page. No
Flutter imports — `dart test` runs it; the app only renders the results
(`apps/ditmesh/lib/ui/tools/`).

| Area | API | File |
|------|-----|------|
| Positions | `GeoPoint`, `GreatCircle` (haversine distance, short / long-path bearing) | `src/geo.dart` |
| Locators | `Maidenhead` (2/4/6/8-character locators both ways), `LocatorArea` | `src/maidenhead.dart` |
| Bands | `AmateurBands` (ITU edges per `IaruRegion`, QRP CW frequencies, wavelength, dipole / quarter-wave length), `BandAllocation` | `src/bands.dart` |
| CW speed | `CwSpeed` (element and gap lengths, characters per minute, PARIS word time) on `morse_core`'s `MorseTiming` | `src/cw_speed.dart` |
| Reports | `RstReport` (format, cut numbers, parse `579` / `5NN` / `59`) | `src/rst.dart` |

```dart
final here = Maidenhead.toPoint('OM89ex');
final there = Maidenhead.toPoint('JN58td');
final km = GreatCircle.distanceKm(here, there);
final heading = GreatCircle.initialBearing(here, there);
final band = AmateurBands.bandFor(7.030, IaruRegion.region3); // 40m
```

Band edges are the ITU Radio Regulations allocations. National band plans
and licence classes are often narrower; the app says so next to the table.

```bash
cd packages/radio_tools && dart test
```
