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

```dart
final here = Maidenhead.toPoint('OM89ex');
final there = Maidenhead.toPoint('JN58td');
final km = GreatCircle.distanceKm(here, there);
final heading = GreatCircle.initialBearing(here, there);
final band = AmateurBands.bandFor(7.030, IaruRegion.region3); // 40m
```

频段边界取自 ITU《无线电规则》的划分。各国频率规划与执照等级通常更窄，应用在表格旁有提示。

```bash
cd packages/radio_tools && dart test
```
