import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import '../../i18n/l10n_extension.dart';
import '../moderation/site_links.dart';
import 'bootstrap_labels.dart';

class BootstrapNodesPage extends StatefulWidget {
  const BootstrapNodesPage({super.key, required this.service});
  final NetworkBootstrapService service;
  @override
  State<BootstrapNodesPage> createState() => _BootstrapNodesPageState();
}

class _BootstrapNodesPageState extends State<BootstrapNodesPage> {
  late Future<BootstrapCatalogue> _catalogue = widget.service.loadNodes();
  final Map<String, BootstrapProbeVerdict> _verdicts = {};
  final Set<String> _busy = {};
  Future<void> _test(BootstrapNode node) async {
    setState(() => _busy.add(node.id));
    BootstrapProbeVerdict result;
    try {
      result = await widget.service.probe(node);
    } on Object {
      result = BootstrapProbeVerdict.unavailable;
    }
    if (!mounted) return;
    setState(() {
      _busy.remove(node.id);
      _verdicts[node.id] = result;
    });
  }

  Future<void> _select(BootstrapNode node) async {
    final s = context.s;
    final verdict = _verdicts[node.id];
    final warning = verdict == null
        ? s.bootstrapNotTestedWarning
        : verdict == BootstrapProbeVerdict.reachable
        ? null
        : verdict.permitsSelection
        ? s.bootstrapInconclusiveWarning
        : s.bootstrapFailedWarning;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.bootstrapSwitchTitle),
        content: Text(
          [s.bootstrapSwitchQuestion, node.endpoint, ?warning].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('bootstrap-switch-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.bootstrapSwitchConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(node.id));
    try {
      await widget.service.selectNode(node);
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.bootstrapOperationFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(node.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.bootstrapChooseNode),
        actions: [
          IconButton(
            tooltip: s.bootstrapRefresh,
            onPressed: () => setState(() {
              _verdicts.clear();
              _catalogue = widget.service.loadNodes();
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<BootstrapCatalogue>(
        future: _catalogue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(s.bootstrapOperationFailed));
          }
          final catalogue = snapshot.data;
          if (catalogue == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (catalogue.fromFallback)
                Padding(
                  key: const ValueKey('bootstrap-list-fallback'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(s.bootstrapFallback),
                ),
              for (final node in catalogue.nodes)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          node.endpoint,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(node.publicKey),
                        if (node.alternateHosts.isNotEmpty)
                          Text(node.alternateHosts.join(', ')),
                        if (node.maintainer != null)
                          Text('${s.bootstrapMaintainer}: ${node.maintainer}'),
                        if (node.location != null)
                          Text('${s.bootstrapLocation}: ${node.location}'),
                        if (node.lastPing != null)
                          Text(
                            '${s.bootstrapLastPing}: ${node.lastPing!.toLocal()}',
                          ),
                        Text(
                          s.bootstrapProtocolStatus(
                            node.udpOnline
                                ? s.bootstrapOnline
                                : s.bootstrapOffline,
                            node.tcpOnline
                                ? s.bootstrapOnline
                                : s.bootstrapOffline,
                          ),
                        ),
                        if (_verdicts[node.id] != null)
                          BootstrapProbeStatus(verdict: _verdicts[node.id]!),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              key: ValueKey('bootstrap-node-test-${node.id}'),
                              onPressed: _busy.contains(node.id)
                                  ? null
                                  : () => _test(node),
                              child: Text(s.bootstrapTestNode),
                            ),
                            FilledButton(
                              key: ValueKey('bootstrap-node-select-${node.id}'),
                              onPressed: _busy.contains(node.id) || !node.online
                                  ? null
                                  : () => _select(node),
                              child: Text(s.bootstrapSwitchConfirm),
                            ),
                          ],
                        ),
                        if (_busy.contains(node.id))
                          const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () =>
                    openSiteLink(context, 'https://nodes.tox.chat/'),
                child: Text(s.bootstrapSource),
              ),
            ],
          );
        },
      ),
    );
  }
}
