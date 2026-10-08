[简体中文](./README.zh-CN.md)

# Localisation (l10n) for the DitMesh app

Flutter's gen-l10n ships English (`en`, template), Simplified Chinese (`zh`),
Traditional Chinese (`zh_Hant`), Japanese (`ja`), Korean (`ko`), German (`de`),
French (`fr`), Spanish (`es`), Portuguese (`pt`) and Russian (`ru`).
Documentation is maintained in English and Simplified Chinese only.

| Path | What |
|------|------|
| `apps/ditmesh/l10n.yaml` | gen-l10n config: output class `S`, non-nullable getter, output in `lib/l10n/generated/` |
| `lib/l10n/app_en.arb` | **Template.** Every key lives here first, with `@key` metadata (description, placeholders) |
| `lib/l10n/app_<locale>.arb` | Complete translations. Every file has the template key set (enforced by `test/i18n/arb_consistency_test.dart`) |
| `lib/l10n/generated/s*.dart` | Generated; never edit. Exempt from the 500-LOC gate by the `**/l10n/**` pattern |
| `lib/i18n/locale_controller.dart` | `LocaleController` (system / every shipped locale) persisted through a `KeyValueStore` |
| `lib/i18n/key_value_store.dart` | `KeyValueStore` interface + `InMemoryKeyValueStore` + `JsonFileKeyValueStore` |
| `lib/i18n/l10n_extension.dart` | `context.s` → `S.of(context)`; re-exports `S` |
| `lib/i18n/language_settings_tile.dart` | `LanguageSettingsTile` for the Me page (+ `showLanguageDialog`) |
| `lib/i18n/chat_error_messages.dart` | `chatErrorMessage(s, code)` / `describeChatError(s, error)` for `ChatException` codes |
| `lib/i18n/current_strings.dart`, `lib/i18n/strings_resolver.dart` | `currentS()` / `StringsResolver` for code without a `BuildContext` (see below) |
| `lib/notifications/**` | `notification*` keys: OS notification titles/bodies, inbox summary plural, Android channel names, Linux action. Resolved via `S Function()` at post time |
| `lib/desktop/**` | `desktop*` keys: tray menu (Show/Hide/Sound/Quit), tooltip plural, unread window title. `DesktopShellController.updateStrings(S)` |
| `lib/i18n/locale_resolution.dart` | `resolveSystemLocales(preferred, supported)`: walks the OS preferred-locale **list** in order, first shipped match wins, else English |
| `tool/ui_literal_guard.dart` (repo root) | CI gate: no hard-coded user-visible prose in `apps/ditmesh/lib` (see below) |

## Wiring (main.dart)

`main()` opens one settings store, `JsonFileKeyValueStore` on
`<application support>/settings.json`, for every backend (fake or Tox); only
if that file cannot be opened does it fall back to an `InMemoryKeyValueStore`.
It is passed to `AppScope` (`localeStore`), which builds the
`LocaleController` on it above `MaterialApp` (an `AppScope` without a store,
as in widget tests, uses memory). Then:

```dart
MaterialApp(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  locale: context.watch<LocaleController>().locale, // null = follow system
  localeListResolutionCallback: LocaleController.resolve,
  ...
)
```

Precedence: an explicit in-app choice (any of the ten shipped languages)
wins. With "System default" (`locale: null`) `LocaleController.resolve` →
`resolveSystemLocales` walks the OS preferred-locale **list** in order and
picks the first language the app ships, so `[it-IT, ja-JP]` gives Japanese
and a list with no shipped language falls back to English. Within Chinese,
an explicit `Hant` script, or a TW / HK / MO region without a script
(Android reports `zh-TW`, iOS `zh-Hant-TW`), maps to Traditional Chinese
(`zh_Hant`); any other Chinese maps to Simplified Chinese (`zh`). Other
languages match their language code. The OS list already contains the
per-app language on Android 13+ and iOS (declared in
`android/app/src/main/res/xml/locale_config.xml`, `CFBundleLocalizations`
and the Runner `*.lproj/InfoPlist.strings`;
`test/i18n/platform_locales_test.dart` keeps those in step with the ARB
files). `currentS()` uses the same resolution for code without a context.

Reference meanings and mnemonics are not ARB messages: each language has one
file, `lib/ui/reference/text/reference_text_<tag>.dart`, registered in
`kReferenceTexts` (`text/reference_texts.dart`) for all ten shipped
languages; `kReferenceLanguages` is derived from its keys. English defines
the rows and their order. Lookup is tiered (`lang_Script_REGION` →
`lang_Script` → `lang_REGION` → `lang` → `en`), so Traditional Chinese reads
`zh_Hant`; English is reached only by a locale with no registered language.
A new ARB locale without a registered reference text fails
`test/reference/reference_texts_test.dart` (see
`doc/i18n/ADDING_A_LANGUAGE.md`, Step 7).

## Using a string

```dart
import '../../i18n/l10n_extension.dart';

Text(context.s.chatSend)                      // plain
Text(context.s.learnLessonOf(lesson, total))  // placeholders
Text(context.s.statsSessions(count))          // ICU plural
```

Outside a widget (controllers, background code) pass the `S` instance in
rather than reaching for a context. `S.of(context)` throws above the
`MaterialApp`, so tests pump `localizationsDelegates: S.localizationsDelegates`.

### Context-free strings (notifications, tray, lifecycle)

Services that outlive any widget take an `S Function()` (default `currentS()`,
which follows `LocaleController.active` — toxee's `currentAppL10n()` scheme)
and call it when they need text, so the *next* notification or tray rebuild is
in the new language with no re-wiring. `AppServices` owns one `StringsResolver`
(a `ChangeNotifier` over the scope's `LocaleController`; fires on the setting
and, while following the system, on OS locale changes), hands notifications
`() => strings.s` and calls `DesktopShellController.updateStrings(strings.s)`
on start and on every change. Product names (`appName`, `DitMesh`) are
placeholders, never translated. Android notification channel names and
descriptions are refreshed on a language change too
(`LocalNotificationsApi.refreshStrings()` re-creates the channels; see
`lib/notifications/README.md`); only notifications already on screen keep
their old language. Tests pin the language with
`lookupS(const Locale('en'))` / `lookupS(const Locale('zh'))` instead of
relying on the host locale.

## Adding a string

1. Add the key to `app_en.arb` **and every translation ARB**. Namespace it by area
   (`chatSendHint`, `learnLessonOf`, `statsTitle`, `accountBackupTitle`,
   `referenceSearchHint`; `action*`, `nav*`, `connection*`,
   `messageStatus*`, `error*`, `language*` for shared strings).
2. Give the template entry an `@key` with a `description` and, for
   placeholders, a `placeholders` map (`{"count": {"type": "int"}}`).
   Counts use ICU plurals: `{count, plural, =1{1 session} other{{count} sessions}}`;
   Chinese has no plural forms, so its branch is usually just
   `{count, plural, other{{count} 次练习}}` (keep any `=0` special cases).
   In translations use grammatical categories such as `one` / `other` for
   European languages and `one` / `few` / `many` / `other` for Russian; an
   exact `=1` alone would miss Russian numbers such as 21.
   The description is for the translator: say **where** the string is shown
   and **what** it means (`"Receive drill: button that plays the round again"`),
   what each placeholder holds and whether it is pre-formatted, and any
   length limit or term to keep (callsigns, Q-codes, `CQ`). Do not point at
   source files or classes. `test/i18n/arb_consistency_test.dart` fails on a
   missing or empty description. Translation ARBs need no `@key` metadata.
3. From `apps/ditmesh`: `flutter gen-l10n` (also runs on build/run because
   `pubspec.yaml` has `generate: true`). Commit the regenerated files.
4. `flutter analyze apps/ditmesh`, `flutter test test/i18n` and
   `dart run tool/ui_literal_guard.dart` (repo root) must stay green.

Ham / Morse vocabulary used in `app_zh.arb` — keep it consistent:
点/划 (dit/dah), 字符速度 (character speed), Farnsworth 间距, 有效速度,
呼号 (callsign), 电键 (key), 直键 (straight key), 双桨 (paddles),
侧音 (sidetone), 音调 (tone), 通联 / QSO, 呼叫 CQ, 报务员 (operator),
听抄 / 抄收 (copy, receive), 发报 / 拍发 (send, key), 译码 (decoded),
规程符号 (prosign), Q 简语 (Q-codes), CW 缩写, Koch 课程/顺序.

Terminology rules (both languages):

* **Morse** is 莫尔斯 (莫尔斯电码), never 摩尔斯 — in `app_zh.arb` and in the
  platform strings (`ios/macos/Runner/zh-Hans.lproj/InfoPlist.strings`).
  Traditional Chinese (`app_zh_Hant.arb`) uses the Taiwan-standard 摩斯; keep
  it consistent there and in `zh-Hant.lproj`.
* **好友 vs 联系人.** A Tox friend (someone added by Tox ID, who can come
  online, receive a request, be removed) is 好友 — "friend", and also the
  English "contact" when it means a friend (`errorPeerOffline`,
  `accountEditProfileBody`). 联系人 is only the broader **Contacts** screen
  (`chatContacts`), which lists friends plus the note-to-self entry.
* **Speed unit.** Words per minute is written `WPM` (`{wpm} WPM`, `chatWpm`)
  in both languages. An unknown speed is `-- WPM` (`learnWpmUnknown`,
  `listenSpeedUnknown`).

## UI literal guard

`dart run tool/ui_literal_guard.dart` (repo root; CI step "UI literal guard
(localisation)") parses every file under `apps/ditmesh/lib` (generated code
skipped) and fails when a string literal containing a letter, after
interpolations are removed, is passed straight to a user-visible sink:
`Text` / `SelectableText`, `TextSpan.text`, `Tooltip.message`,
`Semantics.value`, and named arguments such as `tooltip`, `label`,
`labelText`, `hintText`, `helperText`, `errorText`, `semanticLabel`,
`title`, `subtitle`, `content`. `Text('$n')` or `'—'` pass; `Text('Send')`
fails. The sink table is at the top of the tool.

For content that is genuinely not translatable (callsigns, Q-codes,
prosigns, locator examples) add `// ui-literal-ok: <reason>` at the end of
the line or alone on the line above. The reason is mandatory, and a marker
that no longer covers a flagged literal fails the gate, so exemptions cannot
go stale. The guard does not follow prose routed through data maps,
constants or helpers — review those by hand. Tests:
`test/i18n/ui_literal_guard_test.dart`.

## Migration status

The migration from the old `*_strings.dart` const classes is complete; the
classes and `tool/strings_to_arb.dart` are gone. All interface areas use
`context.s` or receive an `S` instance explicitly, so every shipped
translation covers these callers automatically:

| Area | ARB prefix | Callers |
|------|------------|---------|
| Account and startup | `account*`, `action*`, `connection*`, `error*` | `startup/**`, `ui/account/**`, `ui/pages/me_page.dart`; backup dialogs use `currentS()` |
| Chat, contacts and groups | `chat*`, `messageStatus*` | `ui/chat/**`, `ui/contacts/**`, `ui/groups/**`; timestamp formatting uses `MaterialLocalizations` |
| Learning | `learn*` | `ui/learn/**`; send-feedback helpers take `S` explicitly |
| Statistics | `stats*` | `ui/stats/**`; date formatting uses the current locale |
| Reference and translator | `reference*` | `ui/reference/**`; meanings and mnemonics live in `ui/reference/text/reference_text_<tag>.dart` |
| Microphone decoding | `listen*` | `ui/listen/**`; controllers expose state/errors, widgets resolve text |
| Navigation and shell | `nav*`, `shellOfflineBanner` | `ui/pages/**`, `ui/shell/app_shell.dart` |
| Notifications and desktop | `notification*`, `desktop*` | Services resolve strings at event time or on language changes |

Notification titles and bodies, the desktop tray and the window title are
resolved through `currentS()` / `StringsResolver` (see "Context-free
strings" under "Using a string"), and reference *content* (Q-code /
abbreviation / prosign meanings, punctuation names, digit mnemonics, the
note on the English letter mnemonics, the voiced dit/dah rhythm) is data,
not ARB: one `ReferenceText` per language in
`ui/reference/text/reference_text_<tag>.dart` (types in
`text/reference_text.dart`), registered in `kReferenceTexts`
(`text/reference_texts.dart`). `reference_localized_text.dart` holds the
lookup helpers (`referenceRows()`, which pivots the per-language tables into
per-row maps for `reference_qcodes.dart`, `reference_abbreviations.dart` and
`reference_catalog.dart`; `referenceTextFor`, which `reference_mnemonics.dart`
uses for the rhythm; `referenceLanguageFor`, `localizedReferenceText`, label
separator); `ReferenceEntry.meaning` / `mnemonic` in `reference_catalog.dart`
call them. `test/i18n/arb_consistency_test.dart` enforces that every locale
has the full template key set; `test/reference/reference_texts_test.dart`
that every shipped locale has a complete, translated reference text.
