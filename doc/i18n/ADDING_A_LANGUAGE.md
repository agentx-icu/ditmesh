[简体中文](./ADDING_A_LANGUAGE.zh-CN.md)

# Adding a UI language to DitMesh

DitMesh ships English (`en`, template), Simplified Chinese (`zh`), Traditional
Chinese (`zh_Hant`), Japanese (`ja`), Korean (`ko`), German (`de`), French (`fr`),
Spanish (`es`), Portuguese (`pt`) and Russian (`ru`) through Flutter gen-l10n.
Each translation contains every template message (660 as of 2026-10-03).
Documentation remains English and Simplified Chinese only.

This page explains the shared localisation pipeline and how to extend it.
For daily string work (adding a key) and Morse vocabulary, see
[`apps/ditmesh/lib/l10n/README.md`](../../apps/ditmesh/lib/l10n/README.md).

## 1. How localisation works

### 1.1 gen-l10n and the `S` class

| Piece | Where | Notes |
|---|---|---|
| gen-l10n config | `apps/ditmesh/l10n.yaml` | `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-class: S`, `output-dir: lib/l10n/generated`, `output-localization-file: s.dart`, `nullable-getter: false`, `format: false`. No `synthetic-package` (removed in Flutter 3.41; the key only warns). |
| Auto-generation | `apps/ditmesh/pubspec.yaml` → `flutter: generate: true` | `flutter run` / `flutter build` regenerate; `flutter gen-l10n` does it explicitly. |
| ARB files | `apps/ditmesh/lib/l10n/app_<tag>.arb` | One per locale. `app_en.arb` is the template and the only file that needs `@key` metadata (description, placeholders). 660 message keys as of 2026-10-03. |
| Generated code | `apps/ditmesh/lib/l10n/generated/s.dart`, `s_<language>.dart` (script/region variants such as `SZhHant` live in the base language's file, `s_zh.dart`) | Committed, never edited. Exempt from the 500-LOC gate via the `**/l10n/**` pattern. |
| Access | `context.s` (`lib/i18n/l10n_extension.dart`) or `S.of(context)` | Below `MaterialApp` only; tests pump `localizationsDelegates: S.localizationsDelegates`. |
| Supported set | `S.supportedLocales` | Derived from the ARB files. `LocaleController.supportedLocales` and the language picker read it, so **no Dart list has to be edited to add a language**. |

`main.dart` wires:

```dart
MaterialApp(
  onGenerateTitle: (context) => S.of(context).appName,
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  locale: context.watch<LocaleController>().locale,   // null = follow system
  localeListResolutionCallback: LocaleController.resolve,
  ...
)
```

### 1.2 `LocaleController`: follow-system or manual override

`lib/i18n/locale_controller.dart` is a `ChangeNotifier` provided by `AppScope`
above `MaterialApp`.

- `locale` is the **override** (`null` = follow the system). The Me page's
  `LanguageSettingsTile` (`lib/i18n/language_settings_tile.dart`) sets it.
- `effectiveLocale` is what the UI renders in right now: the override, or the
  OS preferred-locale **list** resolved against `S.supportedLocales` (see
  §1.3). The list is read live from `PlatformDispatcher.instance.locales`
  (injectable through the `systemLocales:` constructor argument for tests).
- Persistence goes through the `KeyValueStore` interface
  (`lib/i18n/key_value_store.dart`). Production uses
  `JsonFileKeyValueStore` on `<application support>/settings.json` (opened in
  `main.dart` regardless of which chat backend is selected, so the fake
  backend persists the language too; the desktop shell shares the same file
  through `DesktopStoreAdapter`). Only if that file cannot be opened does
  `main.dart` fall back to `InMemoryKeyValueStore`, which unit and widget
  tests also use. Key: `i18n.locale`; value: a tag produced by
  `localeTag()` — `en`, `zh`, `zh_Hant`, `pt_BR` (script wins over region).
  `parseLocaleTag()` accepts `-`/`_`, any case and legacy `zh_CN`, so an
  existing preference never needs a migration when a language is added.
- On restore, a saved tag is mapped onto the shipped set with
  `supportedLocaleFor()` (same-language, script/region aware). A removed
  variant therefore lands on a remaining locale of the same language — a
  saved `zh_Hant` becomes a manual `zh` choice in a build without
  `app_zh_Hant.arb`. Only a language with no shipped locale at all falls
  back to "follow the system".

### 1.3 One resolution rule, used three times

`lib/i18n/locale_resolution.dart` has two layers.

**The preference list.** `resolveSystemLocales(preferred, supported)` walks
the OS's whole preferred-locale list, most preferred first. The first entry
that maps to a shipped locale (by the per-locale rules below, without
fallback) wins; only when no entry matches — or the list is null/empty — does
English apply. A user whose OS lists `[it-IT, zh-CN]` therefore gets Chinese,
not English: Italian does not ship, Chinese does.

**One locale.** `resolveSystemLocale(system, supported)` /
`supportedLocaleFor(candidate, supported)` are toxee's per-locale resolver
generalised so that the supported set is data:

1. A language with no ARB → no match (English as the final `fallback`).
2. Chinese: Traditional when the script is `Hant` **or** the region is
   TW / HK / MO with no script (Android reports `zh-TW` without a script, iOS
   reports `zh-Hant-TW`) — *if* a `zh_Hant` ARB ships; otherwise the
   Simplified file (`zh_Hans` if shipped, else plain `zh`).
3. Any other language: exact script match if shipped, else the language-only
   file.
4. Over the OS list (`resolveSystemLocales`): the first preference that rules
   2–3 map to a shipped locale wins; if none does, English.

`resolveSystemLocales` backs `MaterialApp.localeListResolutionCallback`
(`LocaleController.resolve`), `LocaleController.effectiveLocale` and the
context-free `currentLocale()` (which reads `PlatformDispatcher.locales`), so
the widget tree, the settings tile and a notification always agree.
`supportedLocaleFor()` is the per-locale rule without the English fallback
(also used to validate a user choice).

**Precedence.** An explicit choice in the in-app picker always wins. With
"System default" the app follows the OS preferred-locale list, and that list
already includes the OS per-app language (Android 13+ App languages, iOS
Settings → DitMesh → Language), so the OS-level per-app setting works without
any native bridge.

### 1.4 The language catalog (native names)

`lib/i18n/language_catalog.dart::LanguageCatalog.nativeName(locale)` returns a
language's own name — `English`, `简体中文`, `繁體中文`, `日本語`, `العربية`, …
These are **not** ARB keys: an endonym is the same in every UI language (toxee
whitelists `english` as "legitimately identical to English" for the same
reason). The picker lists `S.supportedLocales` and labels each with the
catalog; only "System default" (`languageSystemDefault`) is a translated ARB
string. Lookup order: full tag → `language_Script` → language → the BCP-47 tag
itself, so an unlisted language still gets *a* label. `LanguageCatalog.isRtl`
is the layout-direction hint for `ar` / `he` / `fa` / `ur`.

The catalog is pre-populated well beyond what ships (≈35 entries) so most
additions need no catalog edit at all.

### 1.5 Strings without a `BuildContext` (notifications, tray)

`lib/i18n/current_strings.dart`:

- `currentS()` — the `S` instance for the current UI language, resolved on
  every call from `LocaleController.active` (set by `AppScope` for the app run,
  `null` in unit tests → platform locale). Same contract as toxee's
  `currentAppL10n()`.
- `lookupSFor(locale)` — `lookupS` that survives a persisted locale this build
  no longer ships (falls back to English instead of throwing in a
  notification path).
- `StringsResolver` (`strings_resolver.dart`) — a `ChangeNotifier` view for
  long-lived services (tray menu, persistent notification) that must relabel
  when the user changes the setting or, while following the system, when the
  OS locale changes. It is a `WidgetsBindingObserver` (`didChangeLocales`)
  and does not take over `PlatformDispatcher.onLocaleChanged`.

Notification texts (Android channel names and descriptions, "New message",
friend-request and group-invite notifications), the desktop tray menu and
tooltip, and the desktop window title all read `currentS()` /
`StringsResolver` (or an `S` handed in from it): notifications resolve
through an `S Function()` at post time, the desktop shell receives
`DesktopShellController.updateStrings(strings.s)` on every language change,
and `LocalNotificationsApi.refreshStrings()` re-creates the Android channels
so their names follow the language. A new language therefore reaches these
OS-facing strings with no extra work; only notifications already on screen
keep their old text.

Reference meanings and mnemonics are not ARB messages; they live in one
Dart file per language (§1.6). Every shipped UI language ships them too, and
a new language must add its file in the same change as its ARB (Step 7).

### 1.6 Reference content (Q-codes, abbreviations, mnemonics)

Reference *content* is data, not UI chrome, so it is not in the ARB files:
Q-code and CW-abbreviation meanings, prosign meanings, punctuation names,
the translated digit mnemonics, the note appended to the English phonetic
letter mnemonics, and how dits and dahs are voiced. Each language keeps all
of it in one file:

- `lib/ui/reference/text/reference_text.dart` — the types: `ReferenceText`
  (tables `qCodes`, `abbreviations`, `prosigns`, `punctuation`, plus
  `digitPhrases`, `phraseNote`, `rhythm`) and `ReferenceRhythm` (`dit`,
  `finalDit`, `dah`, `joiner`; `ReferenceRhythm.english` is the default
  `di-DAH`).
- `lib/ui/reference/text/reference_text_<tag>.dart` — one `const
  ReferenceText` per language (`reference_text_en.dart`,
  `reference_text_zh_hant.dart`, …). **English defines the rows and their
  display order**; every other language translates exactly those rows.
- `lib/ui/reference/text/reference_texts.dart` — `kReferenceTexts`, the
  registry keyed like the ARB files (`en`, `zh`, `zh_Hant`, `ja`, `ko`,
  `de`, `fr`, `es`, `pt`, `ru` — all ten shipped UI languages), English
  first.

`lib/ui/reference/reference_localized_text.dart` holds the lookup helpers.
`kReferenceLanguages` is derived from `kReferenceTexts.keys` (never edit it
by hand); `referenceRows()` pivots the per-language tables back into one
map per row for `ReferenceQCodes.meanings`, `ReferenceAbbreviations.meanings`
and the catalog's prosign and punctuation tables; `referenceTextFor(tag)`
returns a language's `ReferenceText`, whose `rhythm` drives
`ReferenceMnemonics.spokenRhythm`. Letter mnemonics stay the English
phonetic phrase in every language (their stress *is* the rhythm), followed
by the language's `phraseNote`; digit mnemonics are descriptive, so each
language translates them in `digitPhrases`. The lookup for a UI locale
tries, most specific first:

`lang_Script_REGION` → `lang_Script` → `lang_REGION` → `lang` → `en`

So a `zh-Hant-TW` UI reads `zh_Hant`, and a region variant nobody ships
(`de-AT`) reads its language (`de`). English is the last tier only for a
locale with no registered language at all; it is not a fallback for an
incomplete translation, because `test/reference/reference_texts_test.dart`
(§1.7) rejects one. Label separators use the full-width colon for `zh` /
`ja`.

### 1.7 What CI checks

| Check | Where | What it guards |
|---|---|---|
| `dart run tool/ui_literal_guard.dart` | `.github/workflows/analyze.yml` ("UI literal guard (localisation)"), `tool/test_pyramid.sh` gates | HARD gate. Parses every `apps/ditmesh/lib/**` file (generated code skipped) and fails on a string literal containing a letter that is passed straight to a user-visible sink (`Text`, `TextSpan.text`, `Tooltip.message`, named `label` / `hintText` / `title` / `tooltip` / …). Exemption: `// ui-literal-ok: <reason>` at the end of the line or alone on the line above; the reason is mandatory and a stale marker fails. Prose routed through data maps or helpers is not seen — review still matters. |
| `test/i18n/arb_consistency_test.dart` | `flutter test apps/ditmesh` | Enumerates **every** `lib/l10n/app_*.arb`: `@@locale` matches the file name, identical key sets, non-empty values, every template placeholder present, every plural has `other{…}`, `appName` untranslated, no `@@TODO` marker left, a fixed list of `error*` keys present in the template (the codes `lib/i18n/chat_error_messages.dart` maps; any other `ChatException` code reads `errorUnknown`). Every template key must also carry a non-empty `@key` `description` that does not point at a deleted `*_strings.dart` / `*Strings.` class. |
| `test/i18n/platform_locales_test.dart` | same | Native language declarations equal the ARB set exactly: Android `res/xml/locale_config.xml` (and `android:localeConfig` in the manifest), iOS/macOS `CFBundleLocalizations`, the iOS/macOS `*.lproj/InfoPlist.strings` set and their Xcode registration; every `NS*UsageDescription` translated in every language. ARB `zh` maps to `zh-Hans`, `zh_Hant` to `zh-Hant`, `pt_BR` to `pt-BR`. |
| `test/i18n/shipped_locales_test.dart` | same | The exact set of ten shipped locales, `CFBundleLocalizations` in both Apple `Info.plist` files, Chinese script/region selection, per-locale persistence and context-free service strings, Russian one/few/many and Portuguese zero-count wording. Update it whenever the shipped set changes. |
| `test/i18n/locale_resolution_test.dart`, `locale_list_resolution_test.dart`, `locale_controller_test.dart`, `language_settings_tile_test.dart`, `language_dialog_save_test.dart`, `strings_resolver_test.dart` | same | Resolution rules (single locale and preference list), persistence tags, picker behaviour (every choice on a 320 × 568 phone), OS-locale relabelling. |
| `test/reference/reference_texts_test.dart` | same | `kReferenceTexts` keys equal the shipped ARB locales exactly (English first), so an `app_<tag>.arb` without a registered `reference_text_<tag>.dart` fails. Each language carries exactly the English rows of `qCodes` / `abbreviations` / `prosigns` / `punctuation`, in the same order, none blank; every non-English language has `digitPhrases` for `0`–`9` and a non-empty `phraseNote`; fewer than 10 % of its rows may be identical to English ("actually translated"); the voiced rhythm is never empty. |
| `flutter analyze apps/ditmesh` | CI analyze step | Generated code compiles; strict lints. |

gen-l10n itself **never fails on a missing translation**; it silently falls
back. A key missing from a base-language file (`app_ja.arb`) compiles to the
English template value. A key missing from a script/region variant
(`app_zh_Hant.arb`) is not emitted at all: the variant class only overrides
what its file contains, so the key inherits the base language (`zh`,
Simplified) — Traditional users would see Simplified text. toxee learned
this the hard way (ja/ko shipped ~110 English strings with a green build),
which is why its `arb_completeness_test.dart` exists and why the consistency
test here enumerates every shipped ARB and requires identical key sets.

## 2. Adding a language, step by step

Example: Italian (`it`), which is not shipped yet. Replace the tag as needed.

### Step 1 — create the ARB

```bash
cd apps/ditmesh/lib/l10n
cp app_en.arb app_it.arb
```

File name = `app_` + the locale tag gen-l10n expects:
`app_<lang>.arb`, `app_<lang>_<Script>.arb` (`app_zh_Hant.arb`) or
`app_<lang>_<REGION>.arb` (`app_pt_BR.arb`). Set the header to match:

```json
{
  "@@locale": "it",
  "appName": "DitMesh",
  ...
}
```

### Step 2 — translate

- Translate every **value**. Keep every `{placeholder}` exactly as in the
  template (the consistency test checks each one).
- ICU plurals must keep an `other{…}` branch:
  `{count, plural, =1{1 session} other{{count} sessions}}`. Languages without
  plural forms (ja, zh, ko) usually collapse to
  `{count, plural, other{{count} 回}}` — keep any `=0` special case the
  template has.
- European languages generally use `one` / `other`. Russian needs `one` /
  `few` / `many` / `other`; exact `=1` alone misses 21, 31 and similar counts.
- Leave `appName` as `DitMesh` (product name, tested to be identical).
- The `@key` metadata blocks are optional outside the template; keeping them
  is harmless, deleting them keeps the file short. While translating you may
  mark an entry with `"description": "@@TODO(l10n): …"`;
  `grep -n '@@TODO' apps/ditmesh/lib/l10n/app_it.arb` lists open work, and
  the consistency test fails until none is left.
- Reuse the ham/Morse vocabulary consistently within the language (the zh
  glossary in `lib/l10n/README.md` is the model: dit/dah, character speed,
  Farnsworth spacing, sidetone, straight key, paddles, callsign, copy, send).

### Step 3 — display name in the language catalog

Open `apps/ditmesh/lib/i18n/language_catalog.dart`. If your tag (or its
language code) is already in `LanguageCatalog._names`, nothing to do — `it` →
`Italiano` is there. Otherwise add one line with the **endonym** (the name in that
language, never translated):

```dart
'cy': 'Cymraeg',
```

For a right-to-left language add its code to the set in `isRtl`. Without a
catalog entry the picker still works but shows the raw tag (`cy`).

### Step 4 — generate

```bash
cd apps/ditmesh
flutter gen-l10n          # writes lib/l10n/generated/s_it.dart, updates s.dart
```

`S.supportedLocales` now contains `Locale('it')`; the delegate's
`isSupported`, the picker and the resolver pick it up with no further edits.
Commit the regenerated files.

### Step 5 — verify

```bash
# repo root
dart run tool/ui_literal_guard.dart           # no hard-coded UI prose
flutter analyze apps/ditmesh
cd apps/ditmesh && flutter test test/i18n test/reference
```

Then run the app (the fake backend is enough:
`flutter run --dart-define=DITMESH_FAKE_BACKEND=true`), open **Me → Language**,
pick Italiano, and confirm the shell relabels immediately. Switch back to
"System default" and set the device language to Italian to exercise the
resolver path.

### Step 6 — test completeness and selection

`test/i18n/arb_consistency_test.dart` discovers every `app_*.arb` and checks key
sets, placeholders and plural branches against the English template. Extend
`shipped_locales_test.dart` when the shipped set changes, and add the new native
name to the small-phone picker cases in `language_settings_tile_test.dart`.
Verify persistence, service strings, system resolution and grammatical counts.

### Step 7 — reference content (required)

Reference content is part of adding a language, not a follow-up:
`test/reference/reference_texts_test.dart` fails as soon as `app_it.arb`
exists without a registered Italian reference text (§1.7).

1. Copy `apps/ditmesh/lib/ui/reference/text/reference_text_en.dart` to
   `reference_text_it.dart` (file name: the ARB tag in lower case,
   `reference_text_zh_hant.dart` for `zh_Hant`) and rename the constant
   (`referenceTextIt`).
2. Translate every value of `qCodes`, `abbreviations`, `prosigns` and
   `punctuation`. Keep the keys and their order exactly as in English —
   English defines the rows; never add, drop or reorder one here. Q-codes,
   abbreviations and prosigns are international and stay as keys; only the
   meanings are translated.
3. Add `digitPhrases` for `'0'`–`'9'` (the English digit phrases describe
   the pattern — "one dit, then four dahs" — so translate the description)
   and a `phraseNote`, appended in the UI after the English phonetic letter
   phrase to explain that its stressed syllables are dahs (see
   `reference_text_zh.dart`: `（英文口诀中重读音节为划）`).
4. Decide the `rhythm`. Leave it out (the default `ReferenceRhythm.english`,
   `di-DAH`) unless the language has a **widely established national
   convention** for voicing Morse that its operators actually use — Chinese
   `嘀嗒` is the example. Do not invent a transliteration of `di-DAH`; when in
   doubt, keep the English default.
5. Import the file in `apps/ditmesh/lib/ui/reference/text/reference_texts.dart`
   and add `'it': referenceTextIt` to `kReferenceTexts` under the ARB tag.
   `kReferenceLanguages` follows automatically.

Then run `flutter test test/reference`.

### Step 8 — platform locale manifests

`test/i18n/platform_locales_test.dart` fails until all of these list exactly
the ARB set (BCP-47 form: `it`, `zh-Hans`, `zh-Hant`, `pt-BR`):

- **iOS / macOS — `CFBundleLocalizations`** in
  `apps/ditmesh/ios/Runner/Info.plist` and `macos/Runner/Info.plist`
  (currently the ten shipped tags `en`, `zh-Hans`, `zh-Hant`, `ja`, `ko`,
  `de`, `fr`, `es`, `pt`, `ru`; `shipped_locales_test.dart` checks them
  too). iOS only offers the per-app language in Settings for languages
  listed here.
- **iOS / macOS — `InfoPlist.strings`.** Add
  `ios/Runner/<tag>.lproj/InfoPlist.strings` and
  `macos/Runner/<tag>.lproj/InfoPlist.strings` translating every
  `NS*UsageDescription` key in the matching `Info.plist` (camera,
  microphone); the translation must differ from the English text and mention
  DitMesh, and `en.lproj` must match `Info.plist` verbatim. Register the file as a new
  localisation of the existing `InfoPlist.strings` variant group in
  `Runner.xcodeproj/project.pbxproj` (Xcode: select the file → File
  inspector → Localization → tick the language) and make sure the tag is in
  `knownRegions`; the test checks both.
- **Android — `res/xml/locale_config.xml`.** Add
  `<locale android:name="<tag>"/>` to
  `apps/ditmesh/android/app/src/main/res/xml/locale_config.xml`, which
  `android:localeConfig` in `AndroidManifest.xml` points at; it is what
  Android 13+ shows under App languages. The file is hand-written on purpose:
  AGP's `generateLocaleConfig` derives the list from Android `res/` and
  dependency resources, not from the Flutter ARB files, and would advertise
  languages the app has no strings for. If you later use
  `resourceConfigurations` / `resConfigs` to shrink the APK, keep the new
  language in that list too.
- **Windows / Linux**: nothing; the locale comes from the OS user profile.

With ten shipped languages every one of these lists carries all ten tags
(`zh` → `zh-Hans`, `zh_Hant` → `zh-Hant`, the rest unchanged), and there is
an `ios/Runner` and a `macos/Runner` `<tag>.lproj/InfoPlist.strings` for each
of them, `en.lproj` included.

## 3. Script and region variants (zh_Hant, pt_BR, …)

Follow toxee's precedent but keep it minimal:

- **Traditional Chinese** ships (2026-10-03) and is the worked example of a
  script variant. `app_zh_Hant.arb` (`"@@locale": "zh_Hant"`) is a
  *complete* file — gen-l10n would silently inherit the Simplified `zh`
  text for any key it lacks (§1.7), and the consistency test rejects a
  partial file anyway. `app_zh.arb` stays the
  Simplified file; there is no separate `app_zh_Hans.arb` (toxee
  has one only as an override layer, and its completeness test deliberately
  excludes it because gen-l10n resolves it through `zh`). The resolver
  routes `zh-Hant-*`, `zh-TW`, `zh-HK`, `zh-MO` to `zh_Hant` and everything
  else Chinese to `zh` with no Chinese-specific list to edit. `LanguageCatalog` labels
  `zh_Hant` as `繁體中文`. Its native tag is `zh-Hant` (Info.plist,
  `InfoPlist.strings`, `locale_config.xml`); its reference content is a full
  Traditional file of its own, `reference_text_zh_hant.dart` registered as
  `zh_Hant` (§1.6), with its own rhythm (`滴答`). gen-l10n emits the variant as a subclass
  (`SZhHant` inside `s_zh.dart`) that overrides only the keys its file
  contains; that is exactly why a partial file would leak Simplified text.
  It is written as Taiwan Mandarin (Morse is 摩斯 there), not Cantonese
  colloquial (toxee's test rejects `咗嘅唔喺哋嚟冇揀`).
- **Region variants** (`app_pt_BR.arb`, `app_en_GB.arb`): gen-l10n requires
  the plain language file (`app_pt.arb`) to exist as the parent. The resolver
  walks the preference list, and for each entry rule 3 matches the script
  only — it does not look at the region, so a `pt-BR` device is not
  guaranteed the `pt_BR` file (it takes the first script-less `pt*` locale in
  `S.supportedLocales`). Extend `resolveSystemLocale` with a region
  preference (as it has for Chinese) in the same change as the first region
  variant.
  Persisted tags for region variants are `pt_BR` (`localeTag`: region only
  when there is no script).
- **RTL** (`ar`, `he`): Flutter flips `Directionality` from the locale
  automatically; use `LanguageCatalog.isRtl` only where a widget needs the hint
  outside the tree (tray menus, notification layout).

## 4. Checklist

- [ ] `apps/ditmesh/lib/l10n/app_<tag>.arb` with `@@locale`, complete, placeholders and `other{}` intact, `appName` unchanged, no `@@TODO` left
- [ ] Endonym present in `LanguageCatalog._names` (and `isRtl` if applicable)
- [ ] `flutter gen-l10n` run; `lib/l10n/generated/` committed
- [ ] `shipped_locales_test.dart` and the small-phone picker cases in `language_settings_tile_test.dart` updated for the new locale
- [ ] Reference content: `lib/ui/reference/text/reference_text_<tag>.dart` with every English row translated (same rows, same order), `digitPhrases` `0`–`9`, `phraseNote`, `rhythm` only for an established national convention; registered in `kReferenceTexts` (`reference_texts.dart`); `test/reference/reference_texts_test.dart` green
- [ ] `CFBundleLocalizations` updated in the iOS and macOS `Info.plist`
- [ ] `<tag>.lproj/InfoPlist.strings` added for iOS and macOS (every `NS*UsageDescription`) and registered in both Xcode projects
- [ ] `<locale android:name="<tag>"/>` added to `android/app/src/main/res/xml/locale_config.xml`
- [ ] `dart run tool/ui_literal_guard.dart`, `flutter analyze apps/ditmesh` and `flutter test apps/ditmesh` green (includes `arb_consistency_test` and `platform_locales_test`)
- [ ] Manual check: Me → Language switch; system-follow with the device set to the new language; on Android 13+ / iOS, the OS per-app language setting with the in-app choice on "System default"
- [ ] Mobile parity: the Dart side is shared; the platform-specific steps are the plist / `InfoPlist.strings` / `locale_config.xml` entries above
