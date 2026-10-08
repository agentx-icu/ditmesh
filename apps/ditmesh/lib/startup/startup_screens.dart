import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../i18n/chat_error_messages.dart';
import '../i18n/l10n_extension.dart';

/// Shown while `inspect()` / `open()` run. Deliberately quiet: a spinner and
/// one line, so a fast launch does not flash a whole screen of chrome.
class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Startup failure with the reason and a retry button. Nothing on disk was
/// changed by a failed inspect/open, so retrying is always safe.
///
/// [error] is whatever `inspect()` / `open()` threw: a `ChatException` is
/// shown as its localized message; anything else as the generic message plus
/// its raw string, which is the only clue a bug report will have.
class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({
    super.key,
    required this.error,
    required this.onRetry,
    this.title,
    this.message,
  });

  final Object? error;
  final VoidCallback onRetry;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final error = this.error;
    final String? detail = switch (error) {
      null => null,
      ChatException() => describeChatError(s, error),
      _ => '${s.errorUnknown}\n$error',
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title ?? s.accountStartupFailedTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ?? s.accountStartupFailedBody,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(s.actionRetry),
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
