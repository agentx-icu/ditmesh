import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../nearby/nearby_controller.dart';
import '../../nearby/nearby_service.dart';
import '../common/app_bar_title.dart';
import '../contacts/friend_request_inbox.dart';
import 'location_settings_page.dart';
import 'nearby_cards.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'nearby'),
      builder: (_) => const NearbyPage(),
    ),
  );

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  late final NearbyController _controller;
  @override
  void initState() {
    super.initState();
    _controller = context.read<NearbyController>();
    _controller.pageOpened();
  }

  @override
  void dispose() {
    _controller.pageClosed();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (await _controller.startIfEnabled()) await _controller.nearby?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final controller = context.watch<NearbyController>();
    final chat = context.read<ChatService>();
    final nearby = controller.nearby;
    final enabled = controller.locationEnabled && controller.nearbyVisible;
    final peers = nearby?.peers ?? [];
    final incoming = nearby?.incomingIntents ?? [];
    final status = switch (nearby?.status) {
      null || NearbyStatus.idle => s.nearbyPaused,
      NearbyStatus.locating => s.nearbyLocating,
      NearbyStatus.joining => s.nearbyJoining,
      NearbyStatus.active =>
        peers.isEmpty ? s.nearbyNobody : s.nearbyPeopleCount(peers.length),
      NearbyStatus.noLocation => s.nearbyNoLocation,
      NearbyStatus.dhtNotReady => s.nearbyDhtNotReady,
      NearbyStatus.cellUnavailable => s.nearbyCellUnavailable,
    };
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(s.peopleNearby),
        actions: [
          IconButton(
            tooltip: s.actionSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => LocationSettingsPage.open(context),
          ),
          if (enabled && nearby != null)
            IconButton(
              tooltip: s.bootstrapRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => unawaited(_refresh()),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('nearby_peer_list'),
              padding: const EdgeInsets.all(16),
              children: [
                FriendRequestInbox(service: chat),
                if (!enabled || nearby == null) ...[
                  const SizedBox(height: 32),
                  Icon(
                    enabled ? Icons.cloud_off : Icons.location_off_outlined,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    enabled ? s.nearbyUnavailable : s.nearbyOff,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton(
                      key: const Key('nearby-open-settings'),
                      onPressed: () => LocationSettingsPage.open(context),
                      child: Text(s.actionSettings),
                    ),
                  ),
                ] else ...[
                  if (nearby.status == NearbyStatus.locating ||
                      nearby.status == NearbyStatus.joining)
                    const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(status),
                  if (nearby.status == NearbyStatus.noLocation)
                    TextButton(
                      onPressed: () => LocationSettingsPage.open(context),
                      child: Text(s.actionSettings),
                    ),
                  const SizedBox(height: 16),
                  for (final intent in incoming)
                    NearbyIncomingCard(
                      key: ValueKey(intent.nonceHex),
                      intent: intent,
                      nearby: nearby,
                      service: chat,
                    ),
                  for (final peer in peers)
                    NearbyPeerCard(
                      key: ValueKey(peer.skHex),
                      peer: peer,
                      nearby: nearby,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
