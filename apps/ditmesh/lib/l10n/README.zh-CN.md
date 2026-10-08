[English](./README.md)

# DitMesh App 的本地化（l10n）

通过 Flutter 的 gen-l10n 提供英语（`en`，模板）、简体中文（`zh`）、繁体中文
（`zh_Hant`）、日语（`ja`）、韩语（`ko`）、德语（`de`）、法语（`fr`）、
西班牙语（`es`）、葡萄牙语（`pt`）和俄语（`ru`）。文档只维护英文和简体中文。

| 路径 | 内容 |
|------|------|
| `apps/ditmesh/l10n.yaml` | gen-l10n 配置：输出类 `S`、非空 getter、输出到 `lib/l10n/generated/` |
| `lib/l10n/app_en.arb` | **模板。** 每个键都先在这里出现，带 `@key` 元数据（description、placeholders） |
| `lib/l10n/app_<locale>.arb` | 完整译文。每份文件的键集合均与模板相同（由 `test/i18n/arb_consistency_test.dart` 强制） |
| `lib/l10n/generated/s*.dart` | 生成物；永不手改。通过 `**/l10n/**` 模式免于 500 行门禁 |
| `lib/i18n/locale_controller.dart` | `LocaleController`（系统 / 所有支持的语言），通过 `KeyValueStore` 持久化 |
| `lib/i18n/key_value_store.dart` | `KeyValueStore` 接口 + `InMemoryKeyValueStore` + `JsonFileKeyValueStore` |
| `lib/i18n/l10n_extension.dart` | `context.s` → `S.of(context)`；重新导出 `S` |
| `lib/i18n/language_settings_tile.dart` | "我"页面的 `LanguageSettingsTile`（+ `showLanguageDialog`） |
| `lib/i18n/chat_error_messages.dart` | 针对 `ChatException` 代码的 `chatErrorMessage(s, code)` / `describeChatError(s, error)` |
| `lib/i18n/current_strings.dart`、`lib/i18n/strings_resolver.dart` | 供没有 `BuildContext` 的代码使用的 `currentS()` / `StringsResolver`（见下文） |
| `lib/notifications/**` | `notification*` 键：系统通知标题/正文、收件箱汇总复数、Android 通知频道名称、Linux 操作。发送时通过 `S Function()` 解析 |
| `lib/desktop/**` | `desktop*` 键：托盘菜单（显示/隐藏/声音/退出）、提示复数、未读窗口标题。`DesktopShellController.updateStrings(S)` |
| `lib/i18n/locale_resolution.dart` | `resolveSystemLocales(preferred, supported)`：按顺序遍历系统首选语言**列表**，第一个已提供的语言胜出，否则英语 |
| `tool/ui_literal_guard.dart`（仓库根目录） | CI 门禁：`apps/ditmesh/lib` 中不得硬编码用户可见文案（见下文） |

## 接线（main.dart）

`main()` 为所有后端（假后端或 Tox）打开同一个设置存储：位于 `<application support>/settings.json`
的 `JsonFileKeyValueStore`；只有该文件无法打开时才回落到 `InMemoryKeyValueStore`。它被传给 `AppScope`
（`localeStore`），由 `AppScope` 在 `MaterialApp` 之上基于它创建 `LocaleController`（没有传入存储的
`AppScope`，例如 widget 测试中，使用内存存储）。然后：

```dart
MaterialApp(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  locale: context.watch<LocaleController>().locale, // null = follow system
  localeListResolutionCallback: LocaleController.resolve,
  ...
)
```

优先级：应用内的显式选择（已提供的十种语言之一）优先。选择"跟随系统"（`locale: null`）时，
`LocaleController.resolve` → `resolveSystemLocales` 按顺序遍历系统首选语言**列表**，取第一个
应用已提供的语言：`[it-IT, ja-JP]` 得到日语，列表里没有任何已提供语言时回落到英语。中文内部：
显式指定 `Hant` 脚本，或没有脚本且地区为 TW / HK / MO（Android 报 `zh-TW`，iOS 报
`zh-Hant-TW`）时使用繁体中文（`zh_Hant`）；其他中文使用简体中文（`zh`）。其他语言按语言代码匹配。
在 Android 13+ 和 iOS 上，这个系统列表已包含"按应用设置的语言"（声明于
`android/app/src/main/res/xml/locale_config.xml`、`CFBundleLocalizations` 和 Runner 的
`*.lproj/InfoPlist.strings`；`test/i18n/platform_locales_test.dart` 保证它们与 ARB 文件一致）。
`currentS()` 对没有 context 的代码使用同一套解析。

参考手册的释义与记忆提示不是 ARB 消息：每种语言一个文件 `lib/ui/reference/text/reference_text_<tag>.dart`，
十种已发布语言都在 `kReferenceTexts`（`text/reference_texts.dart`）中注册；`kReferenceLanguages` 由其键推导。
行及其顺序由英文定义。查找按层级进行（`lang_Script_REGION` → `lang_Script` → `lang_REGION` → `lang` → `en`），
所以繁体中文读取 `zh_Hant`；只有没有任何注册语言的区域设置才会落到英文。新增 ARB 语言而未注册参考文本时，
`test/reference/reference_texts_test.dart` 会失败（见 `doc/i18n/ADDING_A_LANGUAGE.zh-CN.md` 第 7 步）。

## 使用字符串

```dart
import '../../i18n/l10n_extension.dart';

Text(context.s.chatSend)                      // plain
Text(context.s.learnLessonOf(lesson, total))  // placeholders
Text(context.s.statsSessions(count))          // ICU plural
```

在 widget 之外（控制器、后台代码）请把 `S` 实例传进去，而不是去找 context。`S.of(context)` 在
`MaterialApp` 之上会抛出异常，因此测试需要 pump `localizationsDelegates: S.localizationsDelegates`。

### 不依赖 context 的字符串（通知、托盘、生命周期）

比任何 widget 都活得久的服务接收一个 `S Function()`（默认 `currentS()`，跟随
`LocaleController.active`——即 toxee 的 `currentAppL10n()` 方案），在需要文本时调用它，所以
语言切换后的*下一条*通知或下一次托盘重建就是新语言，无需重新接线。`AppServices` 持有一个
`StringsResolver`（基于该作用域 `LocaleController` 的 `ChangeNotifier`；设置变化时触发，跟随
系统时也在系统语言变化时触发），把 `() => strings.s` 交给通知，并在启动时和每次变化时调用
`DesktopShellController.updateStrings(strings.s)`。产品名（`appName`、`DitMesh`）是占位符，
从不翻译。Android 通知频道的名称和描述也会在语言切换时刷新
（`LocalNotificationsApi.refreshStrings()` 重新创建频道；见 `lib/notifications/README.zh-CN.md`）；
只有已经显示在屏幕上的通知保持旧语言。测试用 `lookupS(const Locale('en'))` /
`lookupS(const Locale('zh'))` 固定语言，而不依赖宿主机的语言。

## 添加一个字符串

1. 把键同时加到 `app_en.arb` **和每份翻译 ARB**。按功能区域命名空间（`chatSendHint`、
   `learnLessonOf`、`statsTitle`、`accountBackupTitle`、`referenceSearchHint`；共享字符串用
   `action*`、`nav*`、`connection*`、`messageStatus*`、`error*`、`language*`）。
2. 给模板条目一个带 `description` 的 `@key`，有占位符的话再加一个 `placeholders` 映射
   （`{"count": {"type": "int"}}`）。计数使用 ICU 复数：
   `{count, plural, =1{1 session} other{{count} sessions}}`；中文没有复数形式，
   所以其分支通常就是 `{count, plural, other{{count} 次练习}}`（保留任何 `=0` 特例）。
   译文中，欧洲语言使用 `one` / `other` 等语法类别；俄语使用 `one` / `few` / `many` /
   `other`，仅保留精确匹配的 `=1` 会遗漏 21 等数字的单数形式。
   description 是写给译者的：说明字符串**显示在哪里**、**是什么意思**
   （`"Receive drill: button that plays the round again"`），每个占位符装的是什么、是否已预先格式化，
   以及长度限制或需保留的术语（呼号、Q 简语、`CQ`）。不要指向源文件或类。
   缺少 description 或为空时 `test/i18n/arb_consistency_test.dart` 会失败。翻译 ARB 不需要 `@key` 元数据。
3. 在 `apps/ditmesh` 下执行 `flutter gen-l10n`（因为 `pubspec.yaml` 有 `generate: true`，
   build/run 时也会自动运行）。提交重新生成的文件。
4. `flutter analyze apps/ditmesh`、`flutter test test/i18n` 以及（仓库根目录下的）
   `dart run tool/ui_literal_guard.dart` 必须保持通过。

`app_zh.arb` 中使用的业余无线电 / 莫尔斯词汇——请保持一致：
点/划 (dit/dah), 字符速度 (character speed), Farnsworth 间距, 有效速度,
呼号 (callsign), 电键 (key), 直键 (straight key), 双桨 (paddles),
侧音 (sidetone), 音调 (tone), 通联 / QSO, 呼叫 CQ, 报务员 (operator),
听抄 / 抄收 (copy, receive), 发报 / 拍发 (send, key), 译码 (decoded),
规程符号 (prosign), Q 简语 (Q-codes), CW 缩写, Koch 课程/顺序.

术语规则（两种语言通用）：

* **Morse** 一律译作 莫尔斯（莫尔斯电码），不用 摩尔斯——`app_zh.arb` 和平台字符串
  （`ios/macos/Runner/zh-Hans.lproj/InfoPlist.strings`）都一样。繁体中文（`app_zh_Hant.arb`）
  使用台湾通行的 摩斯；在该文件和 `zh-Hant.lproj` 中保持一致。
* **好友 vs 联系人。** Tox 好友（通过 Tox ID 添加、会上线下线、可发请求、可删除的人）译作 好友——
  英文 "friend" 如此，英文 "contact" 指的是好友时也如此（`errorPeerOffline`、
  `accountEditProfileBody`）。联系人 只用于范围更广的**联系人**页面（`chatContacts`），
  它列出好友外加"给自己的笔记"条目。
* **速度单位。** 每分钟字数在两种语言中都写作 `WPM`（`{wpm} WPM`、`chatWpm`）。速度未知时写作
  `-- WPM`（`learnWpmUnknown`、`listenSpeedUnknown`）。

## UI 字面量守卫

`dart run tool/ui_literal_guard.dart`（仓库根目录；CI 步骤 "UI literal guard (localisation)"）
解析 `apps/ditmesh/lib` 下的每个文件（跳过生成代码），当一个去掉插值后仍含字母的字符串字面量被直接
传给用户可见的接收点时失败：`Text` / `SelectableText`、`TextSpan.text`、`Tooltip.message`、
`Semantics.value`，以及 `tooltip`、`label`、`labelText`、`hintText`、`helperText`、`errorText`、
`semanticLabel`、`title`、`subtitle`、`content` 等命名参数。`Text('$n')` 或 `'—'` 可以通过；
`Text('Send')` 会失败。接收点表在该工具文件顶部。

对确实不可翻译的内容（呼号、Q 简语、规程符号、网格定位示例），在该行末尾或单独在上一行加
`// ui-literal-ok: <原因>`。原因必填；不再覆盖任何被标记字面量的豁免本身也会让门禁失败，所以豁免不会
过期残留。守卫不会追踪经由数据映射、常量或辅助函数传递的文案——这些需人工审查。测试：
`test/i18n/ui_literal_guard_test.dart`。

## 迁移状态

从旧的 `*_strings.dart` 常量类到 ARB 的迁移已经完成；这些类和 `tool/strings_to_arb.dart` 都已删除。
所有界面区域均使用 `context.s`，或显式接收 `S` 实例，因此每种已提供的译文都会自动覆盖这些调用方：

| 区域 | ARB 前缀 | 调用方 |
|------|----------|--------|
| 账号与启动 | `account*`、`action*`、`connection*`、`error*` | `startup/**`、`ui/account/**`、`ui/pages/me_page.dart`；备份对话框使用 `currentS()` |
| 聊天、联系人与群组 | `chat*`、`messageStatus*` | `ui/chat/**`、`ui/contacts/**`、`ui/groups/**`；时间戳通过 `MaterialLocalizations` 格式化 |
| 学习 | `learn*` | `ui/learn/**`；发报反馈辅助函数显式接收 `S` |
| 统计 | `stats*` | `ui/stats/**`；日期按当前语言格式化 |
| 手册与翻译器 | `reference*` | `ui/reference/**`；释义与记忆提示位于 `ui/reference/text/reference_text_<tag>.dart` |
| 麦克风译码 | `listen*` | `ui/listen/**`；控制器暴露状态/错误，由界面解析文本 |
| 导航与外壳 | `nav*`、`shellOfflineBanner` | `ui/pages/**`、`ui/shell/app_shell.dart` |
| 通知与桌面 | `notification*`、`desktop*` | 服务在事件发生或语言变化时解析字符串 |

通知标题与正文、桌面托盘和窗口标题都通过 `currentS()` / `StringsResolver` 解析（见"使用字符串"下的
"不依赖 context 的字符串"）；参考资料*内容*（Q 简语 / 缩写 / 规程符号释义、标点名称、数字助记、
英文字母助记后的说明、点划读法）是数据而不是 ARB：每种语言一个 `ReferenceText`，位于
`ui/reference/text/reference_text_<tag>.dart`（类型在 `text/reference_text.dart`），并在
`kReferenceTexts`（`text/reference_texts.dart`）中注册。`reference_localized_text.dart` 包含查找辅助函数
（`referenceRows()` 把按语言组织的表转成按行组织的映射，供 `reference_qcodes.dart`、
`reference_abbreviations.dart` 和 `reference_catalog.dart` 使用；`referenceTextFor` 供
`reference_mnemonics.dart` 取读法；`referenceLanguageFor`、`localizedReferenceText`、标签分隔符）；
`reference_catalog.dart` 中的 `ReferenceEntry.meaning` / `mnemonic` 调用它们。
`test/i18n/arb_consistency_test.dart` 约束每种语言都具备完整的模板键集合；
`test/reference/reference_texts_test.dart` 约束每种已发布语言都有完整且确实翻译过的参考文本。
