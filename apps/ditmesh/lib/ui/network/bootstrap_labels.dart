import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import '../../i18n/l10n_extension.dart';

String probeLabel(S s, BootstrapProbeVerdict verdict) => switch (verdict) {
  BootstrapProbeVerdict.reachable => s.bootstrapReachable,
  BootstrapProbeVerdict.unreachable => s.bootstrapUnreachable,
  BootstrapProbeVerdict.invalid => s.bootstrapInvalid,
  BootstrapProbeVerdict.udpUnavailable => s.bootstrapUdpUnavailable,
  BootstrapProbeVerdict.unavailable => s.bootstrapProbeUnavailable,
};

/// DHT success, conclusive failure and locally inconclusive probes stay distinct.
class BootstrapProbeStatus extends StatelessWidget {
  const BootstrapProbeStatus({super.key, required this.verdict});
  final BootstrapProbeVerdict verdict;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = verdict == BootstrapProbeVerdict.reachable;
    final failed = !verdict.permitsSelection;
    final color = success
        ? scheme.primary
        : failed
        ? scheme.error
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            success
                ? Icons.check_circle_outline
                : failed
                ? Icons.cancel_outlined
                : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              probeLabel(context.s, verdict),
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
