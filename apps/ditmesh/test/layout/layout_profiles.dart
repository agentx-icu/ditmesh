// Window profiles for the layout tests: every form factor DitMesh ships on,
// in logical pixels, with the device pixel ratio, safe-area padding,
// soft-keyboard inset and text scale a real device of that class reports.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class LayoutProfile {
  const LayoutProfile(
    this.name,
    this.size, {
    this.dpr = 1,
    this.padding = FakeViewPadding.zero,
    this.keyboard = 0,
    this.textScale = 1,
    this.locale = 'en',
  });

  final String name;

  /// Logical size; the physical size is `size * dpr`.
  final Size size;
  final double dpr;

  /// Logical padding (notch, status bar, home indicator).
  final FakeViewPadding padding;

  /// Logical soft-keyboard height.
  final double keyboard;
  final double textScale;
  final String locale;

  /// The demo data only exists in English and Chinese copies.
  String get seedLocale => locale.startsWith('zh') ? 'zh' : 'en';
}

const FakeViewPadding _portraitNotch = FakeViewPadding(top: 47, bottom: 34);
const FakeViewPadding _landscapeNotch = FakeViewPadding(
  left: 47,
  right: 47,
  bottom: 21,
);
const FakeViewPadding _androidBars = FakeViewPadding(top: 24, bottom: 48);
const FakeViewPadding _tabletBars = FakeViewPadding(top: 24, bottom: 20);

const List<LayoutProfile> kLayoutProfiles = [
  // Phones.
  LayoutProfile('phone-small', Size(320, 568), dpr: 2, padding: _androidBars),
  LayoutProfile('phone', Size(390, 844), dpr: 3, padding: _portraitNotch),
  LayoutProfile(
    'phone-large-text',
    Size(390, 844),
    dpr: 3,
    padding: _portraitNotch,
    textScale: 2,
  ),
  LayoutProfile(
    'phone-small-2x',
    Size(320, 568),
    dpr: 2,
    padding: _androidBars,
    textScale: 2,
  ),
  LayoutProfile(
    'phone-small-de',
    Size(320, 568),
    dpr: 2,
    padding: _androidBars,
    locale: 'de',
  ),
  LayoutProfile(
    'phone-small-ru',
    Size(360, 640),
    dpr: 3,
    padding: _androidBars,
    locale: 'ru',
  ),
  LayoutProfile(
    'phone-landscape',
    Size(844, 390),
    dpr: 3,
    padding: _landscapeNotch,
  ),
  LayoutProfile(
    'phone-landscape-keyboard',
    Size(667, 375),
    dpr: 2,
    padding: _landscapeNotch,
    keyboard: 160,
  ),
  // Android split screen (half of a 411 x 891 phone) and freeform.
  LayoutProfile('android-split', Size(411, 420), dpr: 2.625),
  // Tablets.
  LayoutProfile('ipad-third', Size(320, 1080), dpr: 2, padding: _tabletBars),
  LayoutProfile(
    'tablet-portrait',
    Size(820, 1180),
    dpr: 2,
    padding: _tabletBars,
  ),
  LayoutProfile(
    'tablet-landscape',
    Size(1180, 820),
    dpr: 2,
    padding: _tabletBars,
    textScale: 1.3,
  ),
  // Desktop windows: the enforced minimum, 125 % / 150 % Windows scaling,
  // a 4K monitor at 200 %, an ultrawide.
  LayoutProfile('desktop-min', Size(360, 640), dpr: 1),
  LayoutProfile('desktop-short-wide', Size(1024, 640), dpr: 1.5),
  LayoutProfile('desktop', Size(1280, 800), dpr: 1.25),
  LayoutProfile('desktop-4k', Size(1920, 1080), dpr: 2),
  LayoutProfile('desktop-ultrawide', Size(3440, 1440), dpr: 1),
];

/// The profile called [name] in [kLayoutProfiles].
LayoutProfile profileNamed(String name) =>
    kLayoutProfiles.firstWhere((p) => p.name == name);

/// Applies [profile] to the test view (physical size, ratio, insets and
/// text scale) and registers the reset.
void applyProfile(WidgetTester tester, LayoutProfile profile) {
  final view = tester.view;
  view.devicePixelRatio = profile.dpr;
  view.physicalSize = profile.size * profile.dpr;
  FakeViewPadding physical(FakeViewPadding p) => FakeViewPadding(
    left: p.left * profile.dpr,
    top: p.top * profile.dpr,
    right: p.right * profile.dpr,
    bottom: p.bottom * profile.dpr,
  );
  view.padding = physical(profile.padding);
  view.viewPadding = physical(profile.padding);
  view.viewInsets = physical(FakeViewPadding(bottom: profile.keyboard));
  tester.platformDispatcher.textScaleFactorTestValue = profile.textScale;
  addTearDown(view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}
