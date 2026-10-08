import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import '../../i18n/l10n_extension.dart';
import 'bootstrap_labels.dart';

/// A saved custom node can be tested without finding it in the public list.
class BootstrapCurrentNode extends StatefulWidget {
  const BootstrapCurrentNode({
    super.key,
    required this.service,
    required this.node,
  });
  final NetworkBootstrapService service;
  final BootstrapNode node;
  @override
  State<BootstrapCurrentNode> createState() => _BootstrapCurrentNodeState();
}

class _BootstrapCurrentNodeState extends State<BootstrapCurrentNode> {
  bool _testing = false;
  BootstrapProbeVerdict? _verdict;

  @override
  void didUpdateWidget(BootstrapCurrentNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id ||
        oldWidget.service != widget.service) {
      _testing = false;
      _verdict = null;
    }
  }

  Future<void> _test() async {
    final node = widget.node;
    final service = widget.service;
    setState(() => _testing = true);
    BootstrapProbeVerdict verdict;
    try {
      verdict = await service.probe(node);
    } on Object {
      verdict = BootstrapProbeVerdict.unavailable;
    }
    if (!mounted || widget.node.id != node.id || widget.service != service) {
      return;
    }
    setState(() {
      _testing = false;
      _verdict = verdict;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.bootstrapCurrentNode,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(widget.node.endpoint),
            const SizedBox(height: 8),
            Text(s.bootstrapPublicKey),
            SelectableText(widget.node.publicKey),
            if (_verdict != null) BootstrapProbeStatus(verdict: _verdict!),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('bootstrap-current-test'),
              onPressed: _testing ? null : _test,
              child: Text(s.bootstrapTestNode),
            ),
            if (_testing) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
