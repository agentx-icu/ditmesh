import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';
import '../appearance/style_tokens.dart';
import 'chat_layout.dart';
import 'message_status_icon.dart';

/// A user-shared position, with no map/network request until the map action.
class LocationMessageBubble extends StatelessWidget {
  const LocationMessageBubble({
    super.key,
    required this.message,
    this.showSender = false,
    this.launcher,
    this.onRetry,
    this.onCancelSend,
    this.onBookmark,
    this.bookmarked = false,
  });
  final ChatMessage message;
  final bool showSender;
  final Future<bool> Function(Uri uri)? launcher;
  final VoidCallback? onRetry;
  final VoidCallback? onCancelSend;
  final VoidCallback? onBookmark;
  final bool bookmarked;

  static String coordinates(ChatLocation location) =>
      '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';

  static Uri mapsUri(ChatLocation location, {TargetPlatform? platform}) {
    final lat = location.latitude.toStringAsFixed(6);
    final lon = location.longitude.toStringAsFixed(6);
    final target = platform ?? defaultTargetPlatform;
    if (target == TargetPlatform.android) {
      return Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    }
    if (target == TargetPlatform.iOS || target == TargetPlatform.macOS) {
      final label = location.description.isEmpty
          ? '$lat,$lon'
          : location.description;
      return Uri.parse('maps://?ll=$lat,$lon&q=${Uri.encodeComponent(label)}');
    }
    return webMapsUri(location);
  }

  static Uri webMapsUri(ChatLocation location) {
    final lat = location.latitude.toStringAsFixed(6);
    final lon = location.longitude.toStringAsFixed(6);
    return Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=16/$lat/$lon',
    );
  }

  Future<void> _open(BuildContext context, ChatLocation location) async {
    final launch =
        launcher ??
        (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    Future<bool> attempt(Uri uri) async {
      try {
        return await launch(uri);
      } on Object {
        return false;
      }
    }

    final uri = mapsUri(location);
    var opened = await attempt(uri);
    if (!opened && uri.scheme != 'https') {
      opened = await attempt(webMapsUri(location));
    }
    if (!opened && context.mounted) {
      showSnack(context, context.s.chatOpenMapsFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final location = message.location;
    final radius = StyleTokens.of(context)?.bubbleRadius ?? 16;
    final local = message.timestamp.toLocal();
    final material = MaterialLocalizations.of(context);
    final time =
        '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            message.isMine ? 48 : 12,
            4,
            message.isMine ? 12 : 48,
            4,
          ),
          child: Material(
            color: message.isMine
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSender && !message.isMine)
                    Text(
                      message.senderName ?? message.senderId,
                      style: theme.textTheme.labelSmall,
                    ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          s.chatLocationLabel,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (location == null)
                    Text(s.chatLocationInvalid)
                  else ...[
                    if (location.description.isNotEmpty)
                      Text(location.description),
                    SelectableText(coordinates(location)),
                    SelectableText(
                      Maidenhead.fromPoint(
                        GeoPoint(location.latitude, location.longitude),
                        length: 8,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          key: const Key('location_bubble_open_maps'),
                          onPressed: () => unawaited(_open(context, location)),
                          icon: const Icon(Icons.map_outlined),
                          label: Text(s.chatOpenMaps),
                        ),
                        TextButton.icon(
                          key: const Key('location_bubble_copy_coordinates'),
                          onPressed: () =>
                              copyToClipboard(context, coordinates(location)),
                          icon: const Icon(Icons.copy),
                          label: Text(s.chatCopyCoordinates),
                        ),
                      ],
                    ),
                  ],
                  Text(
                    s.chatLocationSnapshot(time),
                    style: theme.textTheme.labelSmall,
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (message.isMine)
                        MessageStatusIcon(message.status, message: message),
                      if (onBookmark != null)
                        IconButton(
                          tooltip: bookmarked
                              ? s.chatRemoveBookmark
                              : s.chatAddBookmark,
                          onPressed: onBookmark,
                          icon: Icon(
                            bookmarked ? Icons.bookmark : Icons.bookmark_border,
                          ),
                        ),
                      if (onRetry != null)
                        TextButton(
                          onPressed: onRetry,
                          child: Text(s.chatRetrySend),
                        ),
                      if (onCancelSend != null)
                        TextButton(
                          onPressed: onCancelSend,
                          child: Text(s.chatCancelSend),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
