import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import '../../nearby/location_source.dart';
import '../../nearby/nearby_controller.dart';
import '../common/app_bar_title.dart';
import '../tools/tool_page.dart';
import 'nearby_page.dart';
import 'nearby_privacy_notice.dart';

String locationIssueText(S s, LocationIssue issue) => switch (issue) {
  LocationIssue.disabled => s.locationDisabledHint,
  LocationIssue.permissionDenied => s.locationPermissionDenied,
  LocationIssue.serviceDisabled => s.locationServiceDisabled,
  LocationIssue.unavailable => s.locationUnavailable,
  LocationIssue.saveFailed => s.locationSaveFailed,
};

class LocationSettingsPage extends StatelessWidget {
  const LocationSettingsPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const LocationSettingsPage()));

  Future<void> _visible(
    BuildContext context,
    NearbyController controller,
    bool value,
  ) async {
    if (value && !await showNearbyPrivacyNotice(context)) return;
    if (!context.mounted) return;
    await controller.setNearbyVisible(value, consent: value);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final controller = context.watch<NearbyController>();
    final fix = controller.fix;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.locationServices)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      key: const Key('settings_location_switch'),
                      secondary: const Icon(Icons.location_on_outlined),
                      title: Text(s.locationServices),
                      subtitle: Text(s.locationServicesDesc),
                      value: controller.locationEnabled,
                      onChanged: controller.busy
                          ? null
                          : (value) =>
                                controller.setLocationEnabled(value).ignore(),
                    ),
                    SwitchListTile(
                      key: const Key('settings_nearby_visible_switch'),
                      secondary: const Icon(Icons.people_outline),
                      title: Text(s.nearbyVisible),
                      subtitle: Text(s.nearbyVisibleDesc),
                      value: controller.nearbyVisible,
                      onChanged: controller.locationEnabled && !controller.busy
                          ? (value) =>
                                unawaited(_visible(context, controller, value))
                          : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.radar),
                      title: Text(s.peopleNearby),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => NearbyPage.open(context),
                    ),
                    const Divider(),
                    if (controller.locationEnabled)
                      CurrentLocationButton(onFix: (_) {}),
                    if (controller.issue case final issue?) ...[
                      const SizedBox(height: 12),
                      Text(
                        locationIssueText(s, issue),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      if (issue == LocationIssue.permissionDenied ||
                          issue == LocationIssue.serviceDisabled ||
                          issue == LocationIssue.unavailable)
                        TextButton(
                          onPressed: () =>
                              controller.location.openSettings().ignore(),
                          child: Text(s.locationSystemSettings),
                        ),
                    ],
                    if (fix != null) ...[
                      const SizedBox(height: 16),
                      ResultRow(
                        label: s.locationCurrent,
                        value:
                            '${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)}',
                      ),
                      ResultRow(
                        label: s.toolsGridLocator,
                        value: Maidenhead.fromPoint(
                          GeoPoint(fix.latitude, fix.longitude),
                          length: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An explicit, one-shot location request; never reads position during build.
class CurrentLocationButton extends StatelessWidget {
  const CurrentLocationButton({super.key, required this.onFix, this.buttonKey});
  final ValueChanged<LocationFix> onFix;
  final Key? buttonKey;

  Future<void> _locate(
    BuildContext context,
    NearbyController controller,
  ) async {
    if (!controller.locationEnabled) {
      await LocationSettingsPage.open(context);
      return;
    }
    final fix = await controller.locate();
    if (!context.mounted) return;
    if (fix != null) {
      onFix(fix);
    } else if (controller.issue case final issue?) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationIssueText(context.s, issue)),
          action:
              issue == LocationIssue.permissionDenied ||
                  issue == LocationIssue.serviceDisabled ||
                  issue == LocationIssue.unavailable
              ? SnackBarAction(
                  label: context.s.locationSystemSettings,
                  onPressed: () => controller.location.openSettings().ignore(),
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NearbyController?>();
    if (controller == null || !controller.hasIdentity) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FilledButton.tonalIcon(
        key: buttonKey,
        onPressed: controller.locating || controller.busy
            ? null
            : () => unawaited(_locate(context, controller)),
        icon: const Icon(Icons.my_location),
        label: Text(
          controller.locating
              ? context.s.nearbyLocating
              : context.s.locationUseCurrent,
        ),
      ),
    );
  }
}
