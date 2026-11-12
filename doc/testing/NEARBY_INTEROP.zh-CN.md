# DitMesh / Toxee 原生互操作测试

[English](./NEARBY_INTEROP.md)

`tool/test_nearby_toxee.py` 启动两个独立 Flutter 测试进程。DitMesh 端使用真实
后端、传输适配器、附近状态机和 `ChatLocation` 编解码；Toxee 端复用已有原生
附近/位置测试，使用其真实状态机、SDK 和 UIKit 发送路径。所有消息数据通过
真实 Tox UDP 套接字传输，文件仅交换引导端点及阶段、验证元数据。

```sh
python3 tool/test_nearby_toxee.py \
  --toxee ../toxee \
  --toxee-harness ../toxee/build/location-verification-2q4l4xk1/flutter-harness \
  --ditmesh-lib build/native/macos-arm64/libtim2tox_ffi.dylib \
  --toxee-lib ../toxee/build/location-verification-2q4l4xk1/native-build/ffi/libtim2tox_ffi.dylib \
  --output build/nearby-toxee-interop/run
```

Toxee harness 是已准备依赖的独立目录，其原生加载器必须解析到 `--toxee-lib`。
已有 Toxee worker 需要启用 test-instance hooks 的原生库；DitMesh 使用普通的
无测试 hook 库。需要指定 Flutter SDK 时使用 `--flutter`。

runner 会复制一份隔离的 Toxee 测试，不修改生产代码。双端按生产默认启用
IPv6；Toxee 原测试显式禁用 IPv6，在 macOS 上可能使不同地址族套接字绑定到
相同 UDP 端口。该测试网络覆盖会记录在 `result.json`。身份及日志使用临时
测试目录，不修改现有账号或 HOME 设置。

两端发现阶段允许等待 180 秒：第二网格可能在加入事件的限流窗口内连通，
随后由生产环境的 60 秒位置刷新定时器补发 presence，最坏需要两个 tick。
测试保留原来的广播频率，等待预算及隔离 worker 的改动记录在结果中。

覆盖两网格发现与去重、退出一格后的剩余路由、加密好友意向、nonce 匹配申请
与接受、双向单聊及 NGC 群聊位置消息（含群内发送者身份）、发现网格与普通
聊天/群组隔离，以及关闭可见性后的对端消失。

`result.json` 要求双进程退出码为 0、所有必要阶段标记、不同原生进程 PID 和
实际收到的原生数据包；跳过测试不能算通过。测试位置是太平洋中的固定合成
坐标，只验证协议，不声称已经验证系统定位或 GPS 硬件。应用的操作系统权限
及实际位置读取需要在连接的设备上单独验证。

## 系统定位验证记录（2026-11-12）

`integration_test/location_device_test.dart` 是显式 opt-in 的真实系统探针，不创建账号、不注入位置，证据不记录坐标。普通验证可用 `--dart-define=DITMESH_LOCATION_DEVICE_TEST=true`；真实前台点击另加 `--dart-define=DITMESH_LOCATION_MANUAL_START=true`。在 `apps/ditmesh` 运行：

```sh
flutter test integration_test/location_device_test.dart -d macos --no-pub --dart-define=DITMESH_LOCATION_MANUAL_START=true
```

首次几轮验证未取得真实定位点：服务开启，但授权请求曾不返回；前台请求返回 granted 后，立即与两秒后的权限查询仍为 denied，单次 API 返回 PermissionDeniedException。跳过显式请求、直接启动前台位置流的独立对照也返回 PositionUpdateException；已取消订阅。以下保留排查过程，最终修复及真实位置互测见文末。应用已加入有界超时及系统设置恢复入口，避免定位设置永远 busy。

证据在忽略的 `build/location-device-verification/`（`summary.json`、`attempt-4.result.json`、`stream-direct.result.json`及日志）。当前没有连接 iOS/Android 真机。上述真实 OS 结果与使用固定合成坐标的原生双端互测结果分别记录，后者已通过附近发现、好友意向及双向单聊/群聊位置消息。

### 本机复测（2026-11-12 17:17–17:30，UTC+8）

- 系统设置中定位总开关与 DitMesh 权限均开启。重新运行 OS 探针仍未取得坐标。
- 使用本机已有 Developer ID 证书、临时 Xcode 配置构建独立原生探针；磁盘签名及 designated requirement 校验通过。前台实际点击“读取真实位置”后，权限请求回调为 granted，但原生权限查询立即及两秒后均为 denied，`hasFix=false`。系统日志另记录 `get_verified_requirement: failed SecCodeCopyGuestWithAttributes`；根因仍需进一步确认。
- 独立探针实际显示了生产位置卡片组件，使用明确标注的太平洋合成坐标；坐标、网格、时间及单次分享提示正常。真实定位坐标未显示、记录或发送。
- 两次原始 100 秒发现等待超时。修正测试等待预算后，日志确认第二路由通过周期广播恢复；两端独立原生进程均退出 0，附近发现、剩余路由、好友意向、双向单聊及群聊位置消息全部通过，两端各收到 4 个附近原生数据包。未修改 Toxee 工作区或生产广播频率。
- 本次相关测试 38 项通过，应用静态分析无问题。

最新证据：`build/nearby-toxee-interop/recheck-production-cadence/result.json`、
`build/location-device-verification/standalone-signed.result.json` 及对应日志。
`signed-developerid-recheck/` 的 integration-test 尝试发生前台点击超时，
不能用作前台点击证据；探针现已在未点击时立即终止，避免继续产生误导报告。

独立原生窗口可在 `apps/ditmesh` 手动运行：

```sh
flutter run -d macos --debug --no-pub --target integration_test/location_probe_app.dart
```

它不创建账号或网络会话；日志不输出坐标。签名对照只使用本地临时配置，
项目签名设置保持原状。

### 授权回归修复与真实位置互测（2026-11-12 17:37–17:52，UTC+8）

根因定位到 `geolocator_apple` 的版本回归：2.4.2 将实例权限查询改为后台线程上的类方法，2.4.3 仍包含该实现。[上游问题 #1819](https://github.com/Baseflow/flutter-geolocator/issues/1819) 报告了同类 macOS 行为，[对应提交](https://github.com/Baseflow/flutter-geolocator/commit/0b3a15bbbd8abadbec2d233a259436b7e6463dba) 展示了改动。本机保持签名和系统开关不变，仅切换到 2.4.1 后成功取得有效真实位置，确认了依赖回归。

应用显式固定 `geolocator_apple: 2.4.1`，不修改全局 Pub 缓存或 Toxee 工作区。
此外，CoreLocation 新 manager 的首次查询可能短暂为 notDetermined（插件映射为 denied）；授权请求现在会在有界时间内确认真实系统状态后才返回 granted。持续拒绝仍返回拒绝，不缓存授权，也不绕过系统检查。两条回归测试先失败、修复后通过。

普通临时签名调试包的前台点击验证结果：`hasFix=true`、`fixValid=true`，
授权后的立即查询及两秒后查询均为 `always`；定位点距读取约 30 毫秒，
精度约 202 米。已有 Developer ID 签名的对照也成功。没有修改项目签名配置、
系统总开关或用户现有账号。

随后使用该 OS 真实位置快照完成 DitMesh ↔ Toxee 双向加密单聊位置消息互测。
两个独立原生进程退出码均为 0，双方接收坐标匹配。附近发现继续使用合成坐标；
真实坐标未广播到公共发现网格，真实位置模式只验证单聊，不创建位置测试群。
普通合成坐标模式保留群聊覆盖。

真实位置验证可先从 `apps/ditmesh` 显式准备一次性私有交接文件：

```sh
flutter run -d macos --debug --no-pub \
  --target integration_test/location_probe_app.dart \
  --dart-define=DITMESH_LOCATION_HANDOFF=true
```

前台点击成功后，日志的 `LOCATION_FIX_HANDOFF` 只输出文件路径。文件位于
应用私有临时目录，包含供本地测试使用的位置快照；报告不包含坐标。将此路径
通过 runner 的 `--real-location-file /private/path/snapshot.json` 传入。
runner 要求快照新鲜、坐标有效且标记来源为真实 OS；它不会自行读取系统定位。
两端使用同一份本机真实快照，不代表两台移动设备各自独立定位。

该模式在写入日志前遮蔽数值和位置正文，阶段证据仅保留匹配结果；临时原生
账号、位置历史及中间副本在结束时清理。本轮也已删除原始交接文件。证据：

- `build/location-device-verification/permission-confirm-fixed.result.json`
- `build/nearby-toxee-interop/real-os-20261112-1747/result.json`
- `permission-confirm-red.log` / `permission-confirm-green.log`（授权回归测试）

完整应用测试 1600 项通过、36 项跳过，另有 4 项私有快照/脱敏测试通过；
应用静态分析及导入、文案、复杂度检查通过。

PR 前独立评审还覆盖了固定版本插件只有一个单次定位回调的问题：Apple 平台
的附近刷新、聊天及网格并发读取现在共享原生请求，各自保留超时，所有调用者
超时后仍可重新读取。macOS/iOS 并发和超时回归测试通过。附近昵称、意向文字
及匹配好友回复只在显示时按现有 `PeerText` 策略清理；签名记录和 nonce 措辞
保持原样，确认流程有 Unicode 控制符回归测试。
