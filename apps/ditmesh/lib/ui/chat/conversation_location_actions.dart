import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../nearby/nearby_controller.dart';
import '../nearby/location_settings_page.dart';
import 'chat_layout.dart';
import 'chat_session_epoch.dart';
import 'conversation_target.dart';
import 'local_message_sends.dart';
import 'location_message_bubble.dart';

/// Explicit sharing and reading of individual history snapshots. Viewing a
/// peer's shared location never requests this device's position or permission.
abstract final class ConversationLocationActions {
  static final _active = Expando<Set<String>>();

  static Future<void> share(
    BuildContext context, {
    required ChatService service,
    required ConversationTarget target,
    bool Function()? isCurrent,
  }) async {
    final active = _active[service] ??= {};
    final operation = 'share:${target.id}';
    if (!active.add(operation)) return;
    final epoch = ChatSessionEpoch(service);
    final token = epoch.capture();
    final identity = context.read<IdentityService?>();
    final account = identity?.current?.publicKey;
    final controller = context.read<NearbyController?>();
    bool current() =>
        context.mounted &&
        (isCurrent?.call() ?? true) &&
        token.isCurrent(service) &&
        account != null &&
        identity?.current?.publicKey == account;
    try {
      if (!current() || controller == null) {
        if (context.mounted) {
          showSnack(context, context.s.chatLocationSendFailed);
        }
        return;
      }
      if (!controller.locationEnabled) {
        await LocationSettingsPage.open(context);
        return;
      }
      showSnack(context, context.s.nearbyLocating);
      final fix = await controller.locate();
      if (!context.mounted || !current()) return;
      if (fix == null) {
        if (controller.issue case final issue?) {
          showSnack(context, locationIssueText(context.s, issue));
        }
        return;
      }
      final location = ChatLocation(
        latitude: fix.latitude,
        longitude: fix.longitude,
      );
      final s = context.s;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          scrollable: true,
          title: Text(s.chatLocationShareTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.chatLocationShareBody(target.title)),
              const SizedBox(height: 12),
              SelectableText(LocationMessageBubble.coordinates(location)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(s.actionCancel),
            ),
            FilledButton(
              key: const Key('chat-location-share-confirm'),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(s.chatSend),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted || !current()) return;
      if (!controller.locationEnabled) {
        showSnack(context, context.s.locationDisabledHint);
        return;
      }
      if (!identical(controller.fix, fix) ||
          DateTime.now().difference(fix.at) > const Duration(minutes: 3)) {
        showSnack(context, context.s.locationUnavailable);
        return;
      }
      final sent = await service.sendText(target.id, location.encode());
      if (!context.mounted || !current()) return;
      LocalMessageSends.forService(service).publish(sent);
      showSnack(context, context.s.chatLocationSent);
    } on Object catch (error) {
      if (context.mounted && current()) {
        showSnack(context, describeChatError(context.s, error));
      }
    } finally {
      epoch.dispose();
      active.remove(operation);
    }
  }

  static Future<void> view(
    BuildContext context, {
    required ChatService service,
    required ConversationTarget target,
    bool Function()? isCurrent,
  }) async {
    if (target.kind != ConversationKind.c2c || target.isSelf) return;
    final active = _active[service] ??= {};
    final operation = 'view:${target.id}';
    if (!active.add(operation)) return;
    final epoch = ChatSessionEpoch(service);
    final token = epoch.capture();
    bool current() =>
        context.mounted &&
        (isCurrent?.call() ?? true) &&
        token.isCurrent(service);
    try {
      if (!context.mounted || !current()) return;
      MessageSearchCursor? cursor;
      ChatMessage? latest;
      do {
        final page = await service.searchMessages(
          target.id,
          MessageSearchQuery(
            text: ChatLocation.prefix,
            senderId: target.peerId,
          ),
          cursor: cursor,
          limit: 20,
        );
        if (!context.mounted || !current()) return;
        latest = page.results
            .where((m) => !m.isMine && m.isLocation && m.location != null)
            .firstOrNull;
        cursor = page.next;
      } while (latest == null && cursor != null);
      if (!context.mounted || !current()) return;
      if (latest == null) {
        showSnack(context, context.s.chatLocationNotShared);
        return;
      }
      final message = latest;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LocationMessageBubble(message: message),
            ),
          ),
        ),
      );
    } on Object catch (error) {
      if (context.mounted && current()) {
        showSnack(context, describeChatError(context.s, error));
      }
    } finally {
      epoch.dispose();
      active.remove(operation);
    }
  }
}
