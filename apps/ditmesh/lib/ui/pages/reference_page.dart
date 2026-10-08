import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../reference/reference.dart';

/// Shell destination hosting the Morse handbook. The translator is reached
/// from the handbook's app bar so both share one playback settings object,
/// which lives here for the lifetime of the shell.
class ReferencePage extends StatefulWidget {
  const ReferencePage({super.key});

  /// Destination label, resolved in the current locale.
  static String title(S s) => s.navReference;

  /// One-line subtitle, resolved in the current locale.
  static String description(S s) => s.navReferenceDescription;

  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> {
  late final ReferencePlaybackSettings _settings;
  bool _ownsSettings = false;

  @override
  void initState() {
    super.initState();
    try {
      _settings = context.read<ReferencePlaybackSettings>();
    } on ProviderNotFoundException {
      _settings = ReferencePlaybackSettings();
      _ownsSettings = true;
    }
  }

  @override
  void dispose() {
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReferencePlaybackSettings>.value(
      value: _settings,
      child: ReferenceScreen(settings: _settings),
    );
  }
}
