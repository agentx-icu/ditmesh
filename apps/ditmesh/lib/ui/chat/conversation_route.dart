import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_layout.dart';
import 'conversation_screen.dart';
import 'conversation_target.dart';

/// [RouteSettings.name] of a pushed conversation; its arguments are the
/// conversation id, so code outside the chat UI can tell which one is open.
const String kConversationRouteName = 'conversation';

/// The route every pushed [ConversationScreen] uses.
Route<void> conversationRoute(ConversationTarget target) =>
    MaterialPageRoute<void>(
      settings: RouteSettings(
        name: kConversationRouteName,
        arguments: target.id,
      ),
      builder: (_) => ConversationScreen(target: target),
    );

/// Opens [target] full-screen (the single-pane layout of the chat and groups
/// pages).
Future<void> pushConversation(
  BuildContext context,
  ConversationTarget target,
) => Navigator.of(context).push(conversationRoute(target));

/// The route on top of [navigator] (without changing anything).
Route<dynamic>? topRoute(NavigatorState navigator) {
  Route<dynamic>? top;
  navigator.popUntil((route) {
    top = route;
    return true;
  });
  return top;
}

/// Opens [target] from outside the conversation UI (a notification tap):
/// keeps an already open route of the same conversation, replaces another
/// conversation on top, and otherwise pushes above whatever flow is open
/// (training, account pages) instead of tearing it down — so no route that
/// guards its exit (a drill in progress) is ever popped from here.
void openConversationRoute(
  NavigatorState navigator,
  ConversationTarget target,
) {
  final RouteSettings? top = topRoute(navigator)?.settings;
  if (top?.name == kConversationRouteName) {
    if (top!.arguments == target.id) return;
    unawaited(navigator.pushReplacement(conversationRoute(target)));
    return;
  }
  unawaited(navigator.push(conversationRoute(target)));
}

/// The two-pane page owned by [page] is laid out as one pane (an iPad
/// rotated to portrait, a desktop window narrowed) while a conversation is
/// still selected for its detail pane: reopen it as a route instead of
/// dropping it. Call from the page's `build`; [selection] reads the current
/// selection and [forget] clears it (with `setState`).
///
/// The reopen happens only while the page is actually on screen: its tab
/// selected ([TickerMode]) **and** its route current. A non-opaque modal
/// (the clear-history confirmation, a sheet) leaves TickerMode on, so the
/// route check is what keeps the conversation from being pushed above the
/// dialog. Returns false while the page is covered or hidden: the caller then
/// keeps the selection and its detail mounted ([singlePaneLayout]) so the
/// dialog's owner stays alive, and this is called again when the page is
/// rebuilt on becoming current / shown (both lookups register dependencies).
///
/// The push waits for the next frame (no navigation during build) and checks
/// again right before it; the selection is forgotten only when the push is
/// made. The detail is not built on the frame that returns true, so the
/// pane's composer is disposed first and flushes its draft; the route's
/// composer then picks it up through the shared per-conversation draft
/// writer in `message_input.dart` (pending text wins over the stored draft).
bool reopenCollapsedDetail(
  State page, {
  required ConversationTarget? Function() selection,
  required VoidCallback forget,
}) {
  final ModalRoute<Object?>? route = ModalRoute.of(page.context);
  bool onScreen() =>
      TickerMode.valuesOf(page.context).enabled && (route?.isCurrent ?? true);
  if (!onScreen()) return false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!page.mounted || isMasterDetail(page.context)) return;
    final ConversationTarget? target = selection();
    // Covered after all (a dialog opened this frame): the next build retries.
    if (target == null || !onScreen()) return;
    forget();
    unawaited(pushConversation(page.context, target));
  });
  return true;
}

/// The single-pane body: [list], plus the still-selected [parkedDetail]
/// kept mounted but hidden (offstage, tickers off, so it is not the active
/// conversation) while [reopenCollapsedDetail] waits for the page to be on
/// screen. Give the detail a [GlobalKey] ([DetailPaneKey]) so it keeps its
/// state when it moves between the two-pane row and this stack.
Widget singlePaneLayout({required Widget list, Widget? parkedDetail}) => Stack(
  fit: StackFit.expand,
  children: <Widget>[
    list,
    if (parkedDetail != null)
      Offstage(child: TickerMode(enabled: false, child: parkedDetail)),
  ],
);

/// One [GlobalKey] per selected conversation id: the detail keeps its state
/// across a layout change, and a different selection gets a fresh screen.
final class DetailPaneKey {
  String? _id;
  GlobalKey _key = GlobalKey();

  GlobalKey of(String id) {
    if (id != _id) {
      _id = id;
      _key = GlobalKey(debugLabel: 'detail_$id');
    }
    return _key;
  }
}
