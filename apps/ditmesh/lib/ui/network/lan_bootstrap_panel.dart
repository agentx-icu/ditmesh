import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../i18n/l10n_extension.dart';
import '../account/backup_actions.dart';

class LanBootstrapPanel extends StatefulWidget {
  const LanBootstrapPanel({
    super.key,
    required this.service,
    required this.configuration,
  });
  final NetworkBootstrapService service;
  final BootstrapConfiguration configuration;
  @override
  State<LanBootstrapPanel> createState() => _LanBootstrapPanelState();
}

class _LanBootstrapPanelState extends State<LanBootstrapPanel> {
  late final _port = TextEditingController(
    text: '${widget.configuration.lanPort}',
  );
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.bootstrapOperationFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _descriptor(BootstrapNode node) =>
      '${node.host}\n${node.port}\n${node.publicKey}';
  @override
  void dispose() {
    _port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final node = widget.configuration.lanNode;
    final port = int.tryParse(_port.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          node == null ? s.bootstrapLanStopped : s.bootstrapLanRunning,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (node == null)
          TextField(
            controller: _port,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: s.bootstrapPort),
          ),
        if (node != null) ...[
          SelectableText(node.endpoint),
          const SizedBox(height: 8),
          SelectableText(node.publicKey),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('bootstrap-lan-copy'),
                onPressed: () => _run(
                  () =>
                      Clipboard.setData(ClipboardData(text: _descriptor(node))),
                ),
                icon: const Icon(Icons.copy),
                label: Text(s.bootstrapCopyNode),
              ),
              Builder(
                builder: (anchor) => OutlinedButton.icon(
                  key: const ValueKey('bootstrap-lan-share'),
                  onPressed: () => _run(() async {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: _descriptor(node),
                        sharePositionOrigin: shareOriginOf(anchor),
                      ),
                    );
                  }),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(s.bootstrapShareNode),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: ValueKey(
            node == null ? 'bootstrap-lan-start' : 'bootstrap-lan-stop',
          ),
          onPressed: _busy || (node == null && (port < 1 || port > 65535))
              ? null
              : () => _run(
                  node == null
                      ? () => widget.service.startLan(port)
                      : widget.service.stopLan,
                ),
          icon: Icon(node == null ? Icons.play_arrow : Icons.stop),
          label: Text(node == null ? s.bootstrapStartLan : s.bootstrapStopLan),
        ),
        const SizedBox(height: 16),
        Text(s.bootstrapLanKeyChanges),
        const SizedBox(height: 8),
        Text(s.bootstrapLanFirewallHint),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}
