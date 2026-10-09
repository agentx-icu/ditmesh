import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import 'bootstrap_labels.dart';

class BootstrapManualForm extends StatefulWidget {
  const BootstrapManualForm({super.key, required this.service, this.current});
  final NetworkBootstrapService service;
  final BootstrapNode? current;
  @override
  State<BootstrapManualForm> createState() => _BootstrapManualFormState();
}

class _BootstrapManualFormState extends State<BootstrapManualForm> {
  late final _host = TextEditingController(text: widget.current?.host ?? '');
  late final _port = TextEditingController(
    text: '${widget.current?.port ?? 33445}',
  );
  late final _key = TextEditingController(
    text: widget.current?.publicKey ?? '',
  );
  BootstrapProbeVerdict? _verdict;
  String? _testedId;
  bool _busy = false;
  BootstrapNode get _node => BootstrapNode(
    host: _host.text.trim(),
    port: int.tryParse(_port.text) ?? 0,
    publicKey: _key.text.trim().toUpperCase(),
  );
  void _edited(String _) => setState(() {
    _verdict = null;
    _testedId = null;
  });
  Future<void> _test() async {
    final node = _node;
    setState(() {
      _busy = true;
      _verdict = null;
      _testedId = null;
    });
    BootstrapProbeVerdict result;
    try {
      result = await widget.service.probe(node);
    } on Object {
      result = BootstrapProbeVerdict.unavailable;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (_node.id == node.id) {
        _verdict = result;
        _testedId = node.id;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.service.selectNode(_node, requireProbe: true);
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
  void didUpdateWidget(covariant BootstrapManualForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current?.id == widget.current?.id) return;
    _host.text = widget.current?.host ?? '';
    _port.text = '${widget.current?.port ?? 33445}';
    _key.text = widget.current?.publicKey ?? '';
    _verdict = null;
    _testedId = null;
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('bootstrap-manual-host'),
          controller: _host,
          autocorrect: false,
          onChanged: _edited,
          decoration: InputDecoration(label: FieldLabel(s.bootstrapHost)),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('bootstrap-manual-port'),
          controller: _port,
          keyboardType: TextInputType.number,
          onChanged: _edited,
          decoration: InputDecoration(label: FieldLabel(s.bootstrapPort)),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('bootstrap-manual-key'),
          controller: _key,
          autocorrect: false,
          onChanged: _edited,
          decoration: InputDecoration(label: FieldLabel(s.bootstrapPublicKey)),
        ),
        const SizedBox(height: 16),
        if (_verdict != null) ...[
          BootstrapProbeStatus(verdict: _verdict!),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('bootstrap-manual-test'),
              onPressed: _busy ? null : _test,
              child: Text(s.bootstrapTestNode),
            ),
            FilledButton(
              key: const ValueKey('bootstrap-manual-save'),
              onPressed:
                  !_busy &&
                      _node.isValid &&
                      _testedId == _node.id &&
                      (_verdict?.permitsSelection ?? false)
                  ? _save
                  : null,
              child: Text(s.bootstrapSaveNode),
            ),
          ],
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}
