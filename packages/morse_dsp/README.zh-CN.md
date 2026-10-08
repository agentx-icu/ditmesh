[English](./README.md)

# morse_dsp

DitMesh 工作区的纯 Dart 音频摩尔斯译码：输入来自麦克风（或文件）的 16 位 PCM，输出译码后的文本。
不引入 Flutter——`dart test` 就能运行，App 只是在其上叠加采集层。

## 流水线

```text
                 ┌──────────────┐
 pcm16 / bytes ─►│  downmix to  │──► SampleBuffer (carries partial blocks)
 (N channels)    │ mono double  │
                 └──────────────┘
                        │  blocks of `blockSize` samples (256 @ 48 kHz ≈ 5.3 ms)
                        ▼
      ┌───────────────────────────────┐        ┌────────────────────────────┐
      │ GoertzelDetector.power(block) │◄─tune──│ ToneFinder (auto-tune)     │
      │ squared tone amplitude, 0..1  │        │ 25 Goertzels over 400–1000 │
      └───────────────────────────────┘        │ Hz, Hann 2048-sample window│
                        │                      │ lock / unlock hysteresis   │
                        ▼                      └────────────────────────────┘
      ┌───────────────────────────────┐
      │ EnvelopeGate.feed(power)      │  peak tracker (AGC) + noise tracker
      │ → GateTransition(on/off, blk) │  → contrast check → two thresholds
      └───────────────────────────────┘  → min on/off debounce
                        │  block index × blockSize / sampleRate  (sample clock)
                        ▼
      ┌───────────────────────────────┐
      │ MorseDecoder (morse_core)     │  keyDown / keyUp / tick
      │ .text .pendingPattern .events │
      └───────────────────────────────┘
```

`AudioMorseDecoder` 是拥有全部四个阶段的门面。时间由已消费的采样数推导，而绝不来自墙上时钟，
因此同样的字节不论如何分块，总能译码出同样的文本。

```dart
final decoder = AudioMorseDecoder();               // 48 kHz, 256-sample blocks
recorderStream.listen((bytes) => decoder.feedBytes(bytes));
decoder.events.listen((e) => print(decoder.text)); // or poll .text
```

## 参数

| 组件 | 参数 | 默认值 | 含义 |
|-----------|-----------|---------|---------|
| `AudioMorseDecoder` | `sampleRate` | 48000 | 输入采样率；每个阶段的计时都由它推导 |
| | `blockSize` | 256 | 每次门控决策的采样数（5.3 ms）。越小边沿越精细，但噪声也越大 |
| | `autoTune` | true | 让 `ToneFinder` 选择频率 |
| | `manualFrequencyHz` | 700 | 关闭自动调谐时使用，也是找到音调之前的回退值 |
| `GoertzelDetector` | `frequencyHz` | — | 频点中心；带宽为 `sampleRate / blockSize`（187.5 Hz） |
| `ToneFinderConfig` | `minHz` / `maxHz` / `stepHz` | 400 / 1000 / 25 | 扫描频带与候选间隔（25 个候选） |
| | `windowSamples` | 2048 | 分析窗（42.7 ms，23 Hz 频点，Hann） |
| | `lockWindows` | 3 | 锁定前需要一致的音调窗数 |
| | `unlockWindows` | 6 | 锁定转移到*另一个*音调前需要一致的窗数；静默从不计入 |
| | `toleranceHz` | 50 | "同一音调"的距离 |
| | `minPeakDb` | −70 | 低于此值（dBFS）的都不算音调 |
| | `minProminenceDb` | 12 | 峰值必须比候选中位数高出这么多（剔除白噪声极大值） |
| `EnvelopeGateConfig` | `onDropDb` / `offDropDb` | 6 / 12 | 高于 `peak − 6 dB` 原始开启，低于 `peak − 12 dB` 关闭（滞回）。6 dB = 一个块中 ≥ 50 % 为音调，因此边沿定位没有偏差 |
| | `noiseMarginDb` | 9 | 阈值与噪声估计的距离永不小于此值（关闭：−3 dB） |
| | `minContrastDb` | 12 | 峰值必须比噪声高出这么多，否则门保持关闭 |
| | `peakDecayDbPerSecond` | 6 | AGC 释放速率 |
| | `noiseAttack` | 0.05 | 安静块上噪声跟踪器的 EMA 系数 |
| | `noiseRiseDbPerSecond` | 2 | 向不可信（音调 / 离群）块缓慢爬升，使噪声台阶最终被采纳 |
| | `noiseOutlierDb` | 10 | 高于噪声估计超过此值的安静块只做缓慢爬升 |
| | `minOn` / `minOff` | 12 ms / 12 ms | 去抖：更短的音调 / 间隔视为咔哒声 / 掉落（向上取整到块） |
| | `meterRangeDb` | 30 | 对比度更小时电平表的满刻度 |
| `SyntheticMorse`（测试用） | `toneHz` / `amplitude` / `snrDb` / `seed` | 700 / 0.4 / null / 1 | 把 `List<MorseElement>` 渲染为 PCM16，带升余弦键控斜坡和有种子的高斯噪声 |

`SyntheticMorse` 中的 SNR 是音调功率与*宽带*噪声功率之比。检测器只看到其约 188 Hz 频点内的噪声，
因此 6 dB 的宽带 SNR 在频点内约为 27 dB；对 256 采样块而言，设计极限大致是 0 dB 宽带。

## 速度

`morse_core` 译码器根据看到的 mark 自适应其点长估计，初始播种为 80 ms（15 WPM）。在 5.3 ms 块
和 12 ms 去抖下，流水线可跟踪 5–40 WPM。如果一次发送的*第一个*字符以划开头且速度远离 15 WPM，
该字符可能被误译；从第一个含点的字符之后一切正常。

## 局限

* **一次一个信号。** 没有多信号分离：音调查找器锁定 400–1000 Hz 内的主导音调，门控只作用于那一个
  频点。通带内有两个电台时译出的是乱码。
* **只处理键控音调。** 连续载波几秒后会被跟踪器当作"噪声"采纳（`noiseRiseDbPerSecond`），
  从而停止门控。
* **语音、音乐、咔哒声。** 任何在该频点内持续超过 `minOn` 的能量都会产生 mark。去抖只能剔除咔哒声，
  剔除不了说话。
* **频率范围。** 默认 400–1000 Hz；可重新调整 `ToneFinderConfig`（并保持 `windowSamples` ≥
  `sampleRate / stepHz`，这样位于两个候选正中间的音调仍能落入两者的主瓣）。
* **采样率必须匹配。** 把 44.1 kHz 音频喂给 48 kHz 译码器会使音调频带和计时偏移 8 %；请用录音器的
  真实采样率构造译码器。
* **计时分辨率是一个块。** mark 边沿被量化到 `blockSize` 个采样（5.3 ms）；超过约 40 WPM 时请用
  128 采样块。

## 测试

```bash
cd packages/morse_dsp && dart test
```

往返测试用 `SyntheticMorse` 在 15 与 25 WPM、600 与 800 Hz、20 与 6 dB SNR 下渲染一句话
（外加立体声下混、轻/响、手动调谐、分块大小确定性），并期望得到完全一致的文本。
