[English](./README.md)

# radio_tools

DitMesh「无线电工具」页背后的业余无线电计算，**纯 Dart**（不引入 Flutter）：`dart test`
即可运行，应用只负责显示（`apps/ditmesh/lib/ui/tools/`）。

| 方面 | API | 文件 |
|------|-----|------|
| 位置 | `GeoPoint`、`GreatCircle`（haversine 距离、短程 / 长程方位） | `src/geo.dart` |
| 网格 | `Maidenhead`（2/4/6/8 位网格双向换算）、`LocatorArea` | `src/maidenhead.dart` |
| 频段 | `AmateurBands`（按 `IaruRegion` 的 ITU 频段边界、QRP CW 频率、波长、偶极 / 四分之一波长）、`BandAllocation` | `src/bands.dart` |
| 报速 | `CwSpeed`（点划与间隔长度、每分钟字符数、PARIS 单词时长），基于 `morse_core` 的 `MorseTiming` | `src/cw_speed.dart` |
| 信号报告 | `RstReport`（格式化、缩略数字、解析 `579` / `5NN` / `59`） | `src/rst.dart` |
| 分贝 | `Decibels`（瓦与 dBm 互换、dB 与功率 / 电压倍数互换）、`SMeterReading`（IARU 1 区 S 表：短波 S9 = -73 dBm、超短波 -93 dBm，每单位 6 dB） | `src/decibels.dart` |
| 驻波比 | `Swr`（由正向 / 反向功率、比值或负载阻抗求得；回波损耗、反射功率占比、失配损耗） | `src/swr.dart` |
| 太阳 | `SolarDay`（按 NOAA 公式计算 UTC 日出、太阳正午、日落与白昼长度；极昼 / 极夜；民用曙暮光天顶角） | `src/solar.dart` |
| 信标 | `NcdxfBeacons`（18 座 NCDXF / IARU 信标，任一时刻五个频率上各是哪座、距某信标下次时隙的时间）、`Beacon` | `src/beacons.dart` |

```dart
final here = Maidenhead.toPoint('OM89ex');
final there = Maidenhead.toPoint('JN58td');
final km = GreatCircle.distanceKm(here, there);
final heading = GreatCircle.initialBearing(here, there);
final band = AmateurBands.bandFor(7.030, IaruRegion.region3); // 40m
final swr = Swr.fromPowers(forwardW: 100, reflectedW: 4); // 1.5:1
final sun = SolarDay.compute(here, DateTime.now()); // UTC 日出 / 日落
final onAir = NcdxfBeacons.onAir(DateTime.now(), 0); // 14.100 MHz 上的信标
```

频段边界取自 ITU《无线电规则》的划分。各国频率规划与执照等级通常更窄，应用在表格旁有提示。

```bash
cd packages/radio_tools && dart test
```
