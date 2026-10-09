import 'dart:async';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';
import '../common/app_bar_title.dart';
import 'bootstrap_current_node.dart';
import 'bootstrap_manual_form.dart';
import 'bootstrap_nodes_page.dart';
import 'lan_bootstrap_panel.dart';

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});
  static void open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const BootstrapPage()));
  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final service = context.read<NetworkBootstrapService?>();
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.bootstrapTitle)),
      body: service == null
          ? Center(child: Text(s.bootstrapServiceUnavailable))
          : StreamBuilder<BootstrapConfiguration>(
              stream: service.changes,
              initialData: service.configuration,
              builder: (context, snapshot) {
                final config = snapshot.data ?? service.configuration;
                return AccountPageBody(
                  maxWidth: 720,
                  children: [
                    Text(s.bootstrapDescription),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final mode in BootstrapMode.values)
                          if (mode != BootstrapMode.lan || config.supportsLan)
                            ChoiceChip(
                              key: ValueKey('bootstrap-mode-${mode.name}'),
                              label: Text(switch (mode) {
                                BootstrapMode.auto => s.bootstrapModeAuto,
                                BootstrapMode.manual => s.bootstrapModeManual,
                                BootstrapMode.lan => s.bootstrapModeLan,
                              }),
                              selected: config.mode == mode,
                              onSelected: _busy
                                  ? null
                                  : (_) => _run(() => service.setMode(mode)),
                            ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(switch (config.mode) {
                      BootstrapMode.auto => s.bootstrapAutoDescription,
                      BootstrapMode.manual => s.bootstrapManualDescription,
                      BootstrapMode.lan => s.bootstrapLanDescription,
                    }),
                    const SizedBox(height: 16),
                    if (config.current != null &&
                        config.mode != BootstrapMode.lan) ...[
                      BootstrapCurrentNode(
                        service: service,
                        node: config.current!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (config.mode != BootstrapMode.lan)
                      OutlinedButton.icon(
                        key: const ValueKey('bootstrap-open-nodes'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BootstrapNodesPage(service: service),
                          ),
                        ),
                        icon: const Icon(Icons.list_alt),
                        label: Text(s.bootstrapChooseNode),
                      ),
                    if (config.mode == BootstrapMode.manual)
                      BootstrapManualForm(
                        service: service,
                        current: config.current,
                      ),
                    if (config.mode == BootstrapMode.lan)
                      LanBootstrapPanel(
                        service: service,
                        configuration: config,
                      ),
                  ],
                );
              },
            ),
    );
  }
}
