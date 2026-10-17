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
| Decibels | `Decibels` (watts <-> dBm, dB <-> power / voltage ratio), `SMeterReading` (IARU Region 1 S-meter: S9 = -73 dBm HF / -93 dBm VHF, 6 dB per unit) | `src/decibels.dart` |
| SWR | `Swr` (from forward / reflected power, a ratio or a load impedance; return loss, reflected share, mismatch loss) | `src/swr.dart` |
| Feedline | `CoaxCable`, `Feedlines` (nominal attenuation tables for common coax and window line, velocity factor), `FeedlineRun` (matched and SWR-added loss, SWR at the radio, power delivered, electrical length) | `src/feedline.dart` |
| Propagation | `Propagation` (free-space path loss, radio / optical horizon, line-of-sight range, dBm to microvolts), `LinkBudget` (EIRP / ERP, received level) | `src/propagation.dart` |
| Circuits | `Resonance` (LC frequency, L or C for a frequency, reactances), `Attenuator` (π / T resistor values), `MinimumLossPad` (two-resistor pad between unequal impedances) | `src/circuits.dart` |
| Matching | `LNetwork` (L-network solutions bringing `R + jX` to a real impedance), `LMatch`, `ReactiveElement` | `src/matching.dart` |
| Sun | `SolarDay` (sunrise, solar noon, sunset and day length in UTC on the NOAA formulas; polar day / night; civil-twilight zenith) | `src/solar.dart` |
| Beacons | `NcdxfBeacons` (the 18 NCDXF / IARU beacons, which one is on each of the five frequencies at a moment, time until a beacon's next slot), `Beacon` | `src/beacons.dart` |

```dart
final here = Maidenhead.toPoint('OM89ex');
final there = Maidenhead.toPoint('JN58td');
final km = GreatCircle.distanceKm(here, there);
final heading = GreatCircle.initialBearing(here, there);
final band = AmateurBands.bandFor(7.030, IaruRegion.region3); // 40m
final swr = Swr.fromPowers(forwardW: 100, reflectedW: 4); // 1.5:1
final run = FeedlineRun(cable: Feedlines.catalogue[3], lengthM: 30, mhz: 144, swrAtLoad: 2);
final loss = Propagation.freeSpacePathLossDb(distanceKm: 50, mhz: 144); // 109.6 dB
final nets = LNetwork.solutions(resistance: 25, frequencyHz: 7.1e6); // 2 L-networks
final sun = SolarDay.compute(here, DateTime.now()); // sunrise / sunset in UTC
final onAir = NcdxfBeacons.onAir(DateTime.now(), 0); // beacon on 14.100 MHz
```

Band edges are the ITU Radio Regulations allocations. National band plans
and licence classes are often narrower; the app says so next to the table.

```bash
cd packages/radio_tools && dart test
```
