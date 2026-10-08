[English](./README.md)

# morse_core

DitMesh 的纯 Dart 摩尔斯电码引擎：字母表、PARIS / Farnsworth 计时、文本 → 时间线编码器，
以及面向手动键控输入的流式译码器。不依赖 Flutter，因此可以在 App、`morse_trainer` /
`morse_io` 以及普通的 `dart test` 中运行。

## API 概览

| 符号 | 用途 |
| --- | --- |
| `MorseAlphabet` | `international`（A–Z、0–9、ITU 标点）、`prosigns`（AR、SK、BT、KN、AS、SN、SOS、CT、HH）、`kochOrder`（LCWO 顺序，43 项）、`encodeChar` / `encodeProsign` / `decodePattern` / `decodeProsignPattern`。 |
| `MorseTiming` | `wpm` + 可选的 `farnsworthWpm`。`dit`、`dah`、`intraGap`、`charGap`、`wordGap` 为 `Duration`（四舍五入到 µs）；`ditMs` 为 double。 |
| `MorseElement` / `MorseElementKind` | 时间线中的一个通/断段：`dit`、`dah`、`intraGap`、`charGap`、`wordGap`。 |
| `MorseEncoder` | `toPattern("SOS")` → `"... --- ..."`，`encode(text, timing)` → `List<MorseElement>`，`totalDuration`。 |
| `MorseDecoder` / `DecoderConfig` / `DecodeEvent` | 流式译码器：`keyDown(at)` / `keyUp(at)` / `tick(now)` / `flush()`；`text`、`pendingPattern`、`estimatedDit`、`events`。 |
| `ChineseTelegraphCode` / `TelegraphCodebook` / `TelegraphUnit` | 中文电码：`codeOf('中')` → `'0022'`、`charsOf('0948')`、`encode(text)`、`transliterate('CQ 中文')` → `'CQ 0022 2429'`（实际键发的内容）、`decode('0022 2429')`。大陆（1983）与台湾 / 香港两套电码本；表由 `tool/gen_telegraph_table.dart` 从 Unicode Unihan（`kMainlandTelegraph` / `kTaiwanTelegraph`）生成到 `src/telegraph/telegraph_table.g.dart`（Unicode License v3，声明见 `THIRD_PARTY_NOTICES.md`）。 |

规程符号（prosign）在文本中用尖括号书写（`CQ <AR>`），译码时也还原为同样的形式。
点划模式字符串中的单词之间用 ` / ` 分隔。

## 计时

* `dit = 1200 / wpm` ms；划 = 3 点；字符内间隔 = 1 点；字符间隔 = 3 点；单词间隔 = 7 点。
* Farnsworth（`farnsworthWpm < wpm`），采用 ARRL 公式，其中 `c = wpm`、
  `s = farnsworthWpm`：PARIS 中的 19 个间隔单位总共得到
  `ta = (60c − 37.2s) / (s·c)` 秒，因此
  `charGap = 3·ta/19`、`wordGap = 7·ta/19`（比例保持 3:7）。元素本身与字符内间隔不变。
  当 `c == s` 时退化为标准间隔。
* 时间线永不以间隔开头或结尾；单词间隔会取代其前面的字符间隔。因此单独的 `PARIS`
  为 43 点；标准的 50 点单词包含其后紧跟的 7 点单词间隔。

## 译码器算法

输入是一串单调递增的 `keyDown` / `keyUp` 时间戳；`tick(now)` 让一段静默在下一次按键之前
就能解析为字符或单词边界，`flush()` 提交最后一个字符。

* **点长估计。** 最近 32 个按下（mark）时长用二中心一维 k-means 分成短、长两簇，初始中心为当前
  估计值 `d` 与 `3d`。聚类在 `log(duration)` 上进行：键控抖动与元素长度成正比，所以在线性尺度上
  划簇比点簇宽三倍，中点边界会落在划簇内部（每吸收一个划都会把估计值拉高，边界进一步内移）。
  在对数尺度上两簇宽度相等，边界落在几何平均（约 1.73 点），正好在两簇之间的空带里。
  `estimatedDit` 是短簇的算术平均。如果所有 mark 看起来都差不多（长/短均值比 < 2），
  则短于按当前估计推导出的划阈值时视为点，否则视为划（估计值 = 均值 / 3）。从不使用总体中位数，
  因此划占多数的文本（`OTTO 000 MOM`）不会使估计偏移。若初始边界导致某一簇为空，
  则用样本极值重新播种，让糟糕的先验自行修正。`adaptive: false` 会把估计值固定为 `initialDit`。
* **阈值**位于中点：mark ≥ `ditDahThreshold`（2.0）× 点长为划；间隔 ≥ `charGapThreshold`
  （2.0）× 点长结束一个字符；间隔 ≥ `wordGapThreshold`（5.0）× 点长结束一个单词。
* **Farnsworth 自适应。** 保留最近 64 个间隔。低于字符间隔倍数的是字符内间隔；其余分成字符间隔簇
  与单词间隔簇（同样的 k-means，以 `3d` / `7d` 播种）。当两簇都明显存在（比值 ≥ 1.8）
  且字符间隔簇明显长于 3 点（> 4 点）时，阈值移到观测到的字符内/字符、字符/单词两簇之间的中点；
  否则沿用配置的倍数。`isFarnsworthAdapted`、`charGapThreshold` 与 `wordGapThreshold`
  暴露实际生效的值。
* **置信度**：mark 与其阈值相距至少 50 % 时为 1.0，到阈值处线性下降到 0.5。字符事件携带其各元素中
  最低的置信度。单词事件的置信度为 1.0：边界在静默越过阈值的那一刻就被上报，此时最终的间隔长度尚未可知。
* **事件**（`events` 是同步广播流）：每次抬键产生 `element`；字符间隔解析完成时产生 `character`
  （`text` = 该字符，或规程符号的 `<NAME>`）；无法译码的模式产生 `unknownPattern`
  （`text` = `<PATTERN>`，同时也追加到 `text`）；`word` 的 `text = ' '`。

### 冷启动与播种

第一个 mark 只与 `DecoderConfig.initialDit`（默认 80 ms ≈ 15 WPM）比较。知道课程速度的训练器应传入
`initialDit: timing.dit`。Farnsworth 间距要在若干字符间隔之后观测到一个真实的单词间隔才会被识别：
在此之前，12 点的字符间隔与慢速的单词间隔无法区分，因此冷启动 Farnsworth 的第一个单词可能被译成
按字母分开。`clearText()` 丢弃已译码的文本但保留学到的计时，正是为了这种预热场景；`reset()`
则忘掉一切。

### 抖动容忍度（实测，213 字符语料，20 个随机种子）

| 抖动模型 | ±20 % | ±30 % | ±35 % |
| --- | --- | --- | --- |
| 三角分布（类人、有界） | 100 % | 最低 99.1 % | 最低 96.7 %，平均 98.5 % |
| 均匀分布（各极值等概率） | 100 % | 最低 95.3 %，平均 98.3 % | 最低 82 %，平均 90.5 % |

均匀 ±35 % 已超出固定 2.0 点中点所能应付的范围：一个 3 单位的划或字符间隔落在 1.95 点的概率与落在
其区间内任何其他位置一样。在该状态下估计器仍保持锁定（不会崩坏），这正是测试套件所固定的行为。

## 运行测试

```bash
export PATH=/home/user/flutter/bin:$PATH
cd /path/to/ditmesh && dart pub get          # workspace root
cd packages/morse_core
dart analyze .
dart test
```
