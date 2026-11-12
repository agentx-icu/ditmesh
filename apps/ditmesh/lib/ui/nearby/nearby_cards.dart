import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import '../../i18n/chat_error_messages.dart';
import '../../nearby/nearby_records.dart';
import '../../nearby/nearby_service.dart';
import '../chat/chat_layout.dart';
import 'nearby_privacy_notice.dart';

class NearbyPeerCard extends StatefulWidget {
  const NearbyPeerCard({super.key, required this.peer, required this.nearby});
  final NearbyPeer peer;
  final NearbyService nearby;
  @override
  State<NearbyPeerCard> createState() => _NearbyPeerCardState();
}

class _NearbyPeerCardState extends State<NearbyPeerCard> {
  bool _busy = false;
  NearbyPeer get peer => widget.peer;
  NearbyService get nearby => widget.nearby;
  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _sayHi(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.s;
    final distance = nearby.distanceTo(peer);
    final distanceText = distance == null
        ? ''
        : distance < 1000
        ? l10n.nearbyDistanceMeters(((distance / 100).ceil() * 100).toInt())
        : l10n.nearbyDistanceKm((distance / 1000).toStringAsFixed(1));
    final name = nearbyDisplayName(peer.name, l10n.nearbyUnnamed);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        isThreeLine: true,
        leading: CircleAvatar(child: Text(name.characters.first.toUpperCase())),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (distanceText.isNotEmpty) Text(distanceText),
            Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: l10n.nearbyBlock,
                  icon: const Icon(Icons.block),
                  onPressed: () {
                    nearby.block(peer);
                    ScaffoldMessenger.maybeOf(context)
                      ?..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(l10n.nearbyBlocked)),
                      );
                  },
                ),
                FilledButton.tonal(
                  onPressed: _busy ? null : () => unawaited(_run()),
                  child: Text(l10n.nearbySayHi),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sayHi(BuildContext context) async {
    final l10n = context.s;
    var draft = '';
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // The wire budget (bytes inside the sealed record) binds before the
          // 140-character limit for non-ASCII text: count what actually fits.
          final used = IntentBody.messageWireBytes(draft.trim());
          final fits =
              used <= IntentBody.maxMessageWireBytes &&
              IntentBody.validMessage(draft.trim());
          return AlertDialog(
            title: Text(nearbyDisplayName(peer.name, l10n.nearbyUnnamed)),
            content: TextField(
              maxLength: NearbyLimits.messageMaxCodePoints,
              maxLines: 3,
              onChanged: (value) => setDialogState(() => draft = value),
              decoration: InputDecoration(
                hintText: l10n.nearbyRequestMessageHint,
                counterText: '$used/${IntentBody.maxMessageWireBytes}',
                errorText: fits ? null : l10n.nearbyRequestTooLong,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: fits
                    ? () => Navigator.of(ctx).pop(draft.trim())
                    : null,
                child: Text(l10n.nearbySendRequest),
              ),
            ],
          );
        },
      ),
    );
    if (message == null || !context.mounted) return;
    // Consent: the intent discloses the user's own Tox ID to this one peer.
    if (!await showNearbyConsent(context, peer.name)) {
      return;
    }
    // The dialogs took time: the page may be gone or nearby stopped.
    if (!context.mounted || !nearby.running) return;
    final result = await nearby.sendIntent(peer, message);
    if (!context.mounted) return;
    final text = switch (result) {
      PendingIntent() => l10n.nearbyRequestSent,
      NearbyIntentFailure.rateLimited => l10n.nearbyRequestLimit,
      NearbyIntentFailure.messageTooLong => l10n.nearbyRequestTooLong,
      NearbyIntentFailure.peerGone => l10n.nearbyPeerGone,
      _ => l10n.nearbyPeerGone,
    };
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class NearbyIncomingCard extends StatefulWidget {
  const NearbyIncomingCard({
    super.key,
    required this.intent,
    required this.nearby,
    required this.service,
  });
  final IncomingIntent intent;
  final NearbyService nearby;
  final ChatService service;
  @override
  State<NearbyIncomingCard> createState() => _NearbyIncomingCardState();
}

class _NearbyIncomingCardState extends State<NearbyIncomingCard> {
  bool _busy = false;
  IncomingIntent get intent => widget.intent;
  NearbyService get nearby => widget.nearby;
  ChatService get service => widget.service;
  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _accept(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.s;
    final name = nearbyDisplayName(intent.fromName, l10n.nearbyUnnamed);
    final message = PeerText.clean(intent.message);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.nearbyIncomingTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(l10n.nearbyIncomingBody(name)),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('“$message”', style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => nearby.dismissIncoming(intent),
                  child: Text(l10n.nearbyIncomingDecline),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : () => unawaited(_run()),
                  child: Text(l10n.nearbyIncomingAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Accept = send the Tox friend request to the disclosed address with the
  /// nonce in its wording; the initiator confirms on its side.
  Future<void> _accept(BuildContext context) async {
    final l10n = context.s;
    if (!await showNearbyConsent(context, intent.fromName)) return;
    if (!context.mounted ||
        !nearby.running ||
        !nearby.incomingIntents.contains(intent)) {
      return;
    }
    try {
      await service.addFriend(
        intent.address.toUpperCase(),
        message: intent.requestWording,
      );
    } on Object catch (error) {
      if (context.mounted) showSnack(context, describeChatError(l10n, error));
      return;
    }
    if (!context.mounted) return;
    nearby.dismissIncoming(intent);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.nearbyRequestSent)));
  }
}
