// Shared phone-form-factor helpers for the mobile layout tests: sizes the
// test view like a real phone (notch / home-indicator padding by
// orientation, optional soft keyboard, Android gesture-navigation insets,
// text scale) and boots the whole app behind a ready fake identity.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import '../account/test_app.dart';

const Size kSmallPhone = Size(320, 568);
const Size kLandscapePhone = Size(844, 390);
const Size kLandscapeSmallPhone = Size(667, 375);

/// An 11" iPad's 1/3 Split View pane: 320 pt wide, full height.
const Size kSplitViewThird = Size(320, 1080);

/// Android gesture navigation: back-gesture zones on both edges and the
/// home-swipe zone at the bottom (`WindowInsets.systemGestureInsets`).
const FakeViewPadding kGestureNavInsets = FakeViewPadding(
  left: 30,
  right: 30,
  bottom: 30,
);

/// Sizes the view like a real phone: notch / home-indicator padding that
/// depends on orientation, an optional soft keyboard and a text scale.
void setPhone(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  double keyboard = 0,
  FakeViewPadding? padding,
  FakeViewPadding gestureInsets = FakeViewPadding.zero,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = padding ?? phonePaddingFor(size);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.view.systemGestureInsets = gestureInsets;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

FakeViewPadding phonePaddingFor(Size size) => size.width > size.height
    ? const FakeViewPadding(left: 47, right: 47, bottom: 21)
    : const FakeViewPadding(top: 47, bottom: 34);

Future<void> bootApp(WidgetTester tester) async {
  final identity = FakeIdentityService.withProfile(
    identity: Identity(
      toxId: FakeIdentityService.toxIdForSeed(1),
      displayName: 'Phone Tester',
    ),
    connectDelay: Duration.zero,
    dataDirectoryPath: freshDataDirectory(),
  );
  await tester.pumpWidget(
    DitmeshApp(
      backend: FakeBackendFactory(identityService: identity),
      backupFiles: FakeBackupFileGateway(),
      localeStore: acceptedTermsStore(),
    ),
  );
  await settle(tester);
}

Finder navLabel(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
  matching: find.text(label),
);
