import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';

/// Names come from signed peers, whose identity and text are still untrusted.
/// Keep wire records intact and apply the shared display policy at the UI.
String nearbyDisplayName(String raw, String fallback) {
  final name = PeerText.singleLine(raw);
  return name.isEmpty ? fallback : name;
}

/// Shown when "Visible to people nearby" is first turned on: what is
/// shared, with whom, and what is not (plan §4.5). Returns true when the user
/// accepts.
Future<bool> showNearbyPrivacyNotice(BuildContext context) async {
  final l10n = context.s;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.nearbyPrivacyTitle),
      content: SingleChildScrollView(child: Text(l10n.nearbyPrivacyBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.nearbyPrivacyAccept),
        ),
      ],
    ),
  );
  return accepted ?? false;
}

/// Consent before an intent discloses the user's Tox ID to one chosen peer.
Future<bool> showNearbyConsent(BuildContext context, String peerName) async {
  final l10n = context.s;
  final name = nearbyDisplayName(peerName, l10n.nearbyUnnamed);
  final accepted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.nearbyConsentTitle),
      content: Text(l10n.nearbyConsentBody(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.nearbySendRequest),
        ),
      ],
    ),
  );
  return accepted ?? false;
}
