import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../keying/key_profile.dart';
import '../../../keying/key_profiles.dart';
import '../../../training/training_settings.dart';

/// Desktop hint under the on-screen key(s): which keyboard keys drive them.
/// Hidden on touch platforms by the caller.
class KeyerLegend extends StatelessWidget {
  const KeyerLegend({super.key, required this.mode});

  final KeyerMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = KeyProfiles.of(context);
    final text = !profile.isDefault
        ? context.s.keysHintCustom(keyLabels(profile.keysFor(mode)))
        : mode.isPaddle
        ? context.s.learnLegendPaddles
        : context.s.learnLegendStraight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.keyboard_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
