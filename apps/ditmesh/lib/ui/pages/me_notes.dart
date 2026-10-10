import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';

/// Short explanations at the top of the Me page's About section.
///
/// The background note is shown on Android and iOS only: a phone pauses
/// (iOS) or freezes and may kill (Android) a backgrounded DitMesh, so it
/// stops receiving until it is opened again. Desktop builds keep running and
/// connected when minimised, where the note would be wrong. The screen-reader
/// note applies to every platform.
class MeNotes extends StatelessWidget {
  const MeNotes({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isTouchPlatform)
          _Note(
            key: const ValueKey('me-note-background'),
            icon: Icons.phonelink_off,
            title: s.meNoteBackgroundTitle,
            body: s.meNoteBackgroundBody,
          ),
        _Note(
          key: const ValueKey('me-note-screen-reader'),
          icon: Icons.accessibility_new,
          title: s.meNoteScreenReaderTitle,
          body: s.meNoteScreenReaderBody,
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
    );
  }
}
