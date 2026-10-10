[English](./README.md)

# morse_io

DitMesh 与 MorseCQ 共用的 Flutter I/O 层（两个仓库各存一份完全相同的副本）：把 `morse_core` 的时间线渲染为**声音**、**触觉反馈**和**闪光**，
并把屏幕 / 键盘上的**键控**转成 `MorseDecoder` 事件。目标平台为 Android、iOS、macOS、Windows
和 Linux。

## 架构

```
                 List<MorseElement>            paddles / key / keyboard
                        │                                 │
                  ┌─────▼─────┐                 ┌─────────▼─────────┐
                  │MorsePlayer│                 │ StraightKey       │
                  │ (Clock)   │                 │ IambicKeyer(Clock)│
                  └──┬─────┬──┘                 └───┬───────────┬───┘
     PlayerEvent ◄───┘     │ on()/off()             │ on()/off() │ keyDown/keyUp(at)
                           ▼                        ▼            ▼
                       MorseSink ◄──────────────────┘        KeyTarget ─► MorseDecoder
              ┌───────────┼──────────────┬─────────────┐
        SidetoneSink  HapticSink     FlashSink     CompositeSink
        (flutter_soloud) (HapticFeedback  (ValueListenable
                          + vibration)    + torch_light)
```

* `lib/src/` 下**一个文件只管一件事**。公共 API 从 `lib/morse_io.dart` 重新导出；测试替身从
  `lib/testing.dart` 导出。
* **`Clock`**（`now()`、`schedule(delay, cb)`）在所有与时间相关的地方都通过注入获得。默认是
  `SystemClock.shared`，这样 widget、键控器和译码器的 `tick` 共享同一条时间线；`FakeClock`
  驱动测试。
* **`MorseSink`** 刻意做得很"笨"（`prepare / on / off / dispose`）。所有计时都在 `MorsePlayer`
  和键控器里，因此声音、振动和闪光保持采样级对齐。
* **`MorsePlayer`** 把每个边界都安排在*绝对*时间上（`startAt + cumulativeOffset`），迟到的定时器
  永远不会累积漂移；`test/player_test.dart` 用 `FakeClock(timerLatency:)` 证明了这一点。
* **`IambicKeyer`** 是一个显式的 `idle → mark → gap` 状态机，带点/划记忆；模式 B 的额外元素来自
  "元素开始时对侧桨被按住"的锁存，模式 A 在挤压完全松开时清除该锁存。
* **`KeyTarget`** 之所以存在，是因为 `MorseDecoder` 是 `final`；用 `MorseDecoderTarget` 包装真正的
  译码器。`KeyerTiming` 携带显式的点/划/间隔时长；在 App 中用 `KeyerTiming.fromMorseTiming` 构建。
* 键控器的状态转换是 `MorseKeyEvent`（不是 Flutter 拥有的 `KeyEvent`）。

## 插件及选择这些版本的原因

| 插件 | 版本 | 平台（pubspec `flutter.plugin.platforms`） | 说明 |
| --- | --- | --- | --- |
| `flutter_soloud` | `^4.1.7` | android, ios, linux, macos, windows (+web) | 5.x（5.0.0-pre.2+）改为 native-asset hooks，需要 `native_toolchain_c ^0.19.4` → `meta ^1.19`，而 Flutter 3.41.9 把 meta 固定在 1.17.0；pub 无法解析。4.1.7 是能解析的最新版本，且是经典 FFI 插件，因此 `flutter test` 永远不会编译 C 代码。 |
| `vibration` | `^3.2.1` | android, ios | 时长精确的 start/cancel 脉冲；`hasCustomVibrationsSupport()` 为 false 时回退到 `HapticFeedback.heavyImpact()`。 |
| `torch_light` | `^1.1.0` | android, ios | 2.0.0 需要 Dart 3.12 / Flutter 3.44。1.1.0 是普通的 `MethodChannel` 插件，在桌面端是惰性的，而且 `FlashSink` 在桌面端本来也不会调用它。 |

每个插件都藏在一个接口后面（`SoloudApi`、`HapticApi`、`TorchApi`），并各有一个生产适配器
（`FlutterSoloudApi`、`FlutterHapticApi`、`TorchLightApi`）。测试注入假实现；CI 永远不会触碰原生的
音频、振动或相机代码。

## 侧音方案

`SidetoneSink.prepare()` 初始化 SoLoud（48 kHz、512 帧缓冲、单声道），加载一个 `WaveForm.sin`
声源，把它调到 `frequencyHz`（默认 700），然后**以音量 0 循环播放**，并保护它不被 voice culling
回收。`on()` / `off()` 只调用带 5 ms 斜坡的 `fadeVolume(voice, target, ramp)`：包络由混音器施加，
所以键控热路径上没有分配、解码或调度，门控边沿也没有"咔哒"声。音调播放期间可以随时改变频率和音量。
如果 App 已经初始化了 SoLoud，sink 会共享该引擎，并在 dispose 时不调用 `deinit()`。

## 各平台说明（需要真机验证）

下面的内容都无法在 CI 中运行（没有音频设备、振动马达、相机或 GPU）。

### 所有平台
* **侧音延迟目标 < 30 ms**（按键到出声）。用接触式麦克风 / 示波器测量，或同时录制屏幕点击与
  扬声器。预期约为 2 × bufferSize（512/48 kHz 时 ≈ 21 ms）加上操作系统的输出延迟。设备撑得住的话
  可以降低 `FlutterSoloudApi(bufferSize: 256)`；留意欠载引起的爆音。
* 确认 5 ms 斜坡在设备扬声器上 700 Hz 时没有"咔哒"声；若有，把 `SidetoneSink(ramp:)` 提高到
  8–10 ms。
* 负载下 `MorsePlayer` 的计时精度（Dart 定时器不是实时的；漂移补偿让边界保持诚实，但每个边沿
  1–4 ms 的抖动是正常的）。

### iOS
* **音频会话**：`flutter_soloud` 4.x 以 `sessionCategory = none` 运行 miniaudio，且从不激活会话，
  会话归 App 管。`FlutterSoloudApi` 在启动引擎前（经 `audio_session`，`PlatformAudioSessionApi`）
  设为 `playback` + `mixWithOthers`：静音开关打开时侧音照常发声，也不会打断用户的音乐。`record`
  插件会把会话留在 `playAndRecord`；App 的麦克风源在采集结束后调用 `configureForPlayback()`。
* **后台**：App 进入后台时（`AppForeground`，仅 Android/iOS）`SidetoneSink` 停掉静音循环 voice，
  引擎随之让设备空闲，后台不播放任何声音；回到前台时重建 voice。因此 App 不声明 `audio` 后台模式
  （它不会被用到；App Review 2.5.4）。后台的按键被忽略。
* **中断**：每次 `on()` 先调用 `resumeVoice`（`setPause(false)`，会重启被系统停掉的设备），并替换
  丢失的 voice，因此结束通知从未到达的来电 / Siri 中断不会让侧音一直失声。需真机验证：来电后、
  Siri 后、在别的 App 播放音乐后的侧音。
* **屏幕**：免手持的会话运行期间持有 `WakelockScreenWake`（Listen 即如此），否则自动锁屏会把
  App 送入后台。
* 触觉反馈：`Vibration.vibrate(duration:)` 使用 `CHHapticEngine`（iPhone 8+）；`cancel()` 只对这类
  自定义触觉有效。脉冲起始延迟通常为 20–40 ms，这里无法测量。
* 闪光灯：`torch_light` 不需要 Info.plist 条目，但相机不能被其他地方占用。

### Android
* `flutter_soloud` 默认使用 AAudio 低延迟（MMAP）；在中端设备上验证 512 帧不会欠载，并且该音频流
  不会被屏幕录制捕获（MMAP 下属预期行为）。
* 触觉反馈：`hasCustomVibrationsSupport()` 决定使用 start/cancel 还是 impact。需要
  `<uses-permission android:name="android.permission.VIBRATE"/>`。振幅控制因 OEM 而异；脉冲长度
  精度最好也只有 ± 约 10 ms。
* 闪光灯：`torch_light` 需要声明 `android.permission.CAMERA` 和
  `<uses-feature android:name="android.hardware.camera.flash"/>`。

### macOS / Windows / Linux
* 触觉反馈和闪光灯会被编译进去，但由 `defaultTargetPlatform` 门控关闭
  （`HapticSink.isEnabled == false`、`FlashSink.torchActive == false`）。
* 键盘键控（`KeyboardKeyBinding`：空格 = 直键，左/右 Ctrl = 点/划）是主要输入方式；验证在
  Linux/Wayland 上 Ctrl 的抬键事件能到达，并且操作系统的按键重复不会泄漏（代码中已忽略重复事件）。
* macOS：`flutter_soloud` 需要 App 沙盒允许音频输出（默认允许）。Linux：ALSA/PulseAudio 设备选择
  由 miniaudio 负责；测试耳机热插拔。

## CI 无法验证的内容

* 可听的输出、真实延迟、无爆音包络、扬声器/耳机路由、静音开关行为、音频会话中断。
* 振动是否存在、强度、脉冲长度精度、`cancel()` 支持。
* 闪光灯可用性、亮度、相机争用。
* 真实触摸屏的多点触控行为（测试使用合成指针）以及各操作系统的硬件按键重复语义。
* 真实调度器负载下的定时器抖动。

其余一切——调度、状态机、sink 调用序列、widget 的指针/键盘处理——都由
`flutter test packages/morse_io` 覆盖。

## 开发

```bash
export PATH=/home/user/flutter/bin:$PATH
flutter pub get                       # at the workspace root
flutter analyze packages/morse_io
flutter test packages/morse_io
```
