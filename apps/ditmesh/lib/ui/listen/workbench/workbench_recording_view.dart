part of 'workbench_screen.dart';

extension _WorkbenchRecordingView on _WorkbenchScreenState {
  Widget _empty(BuildContext context, WorkbenchController c) {
    final s = context.s;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.audio_file_outlined,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(s.workbenchEmpty, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          s.workbenchFormats,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          s.workbenchBackupNote,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (c.busy)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton.icon(
            key: const ValueKey('workbench-import-empty'),
            onPressed: _mediaBusy ? null : _import,
            icon: const Icon(Icons.file_open_outlined),
            label: Text(s.workbenchImport),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
      ],
    );
  }

  Widget _loaded(WorkbenchController c) {
    final s = context.s;
    final theme = Theme.of(context);
    final info = c.info!;
    final rate = (info.sampleRate / 1000).toStringAsFixed(
      info.sampleRate % 1000 == 0 ? 0 : 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          c.name ?? '',
          key: const ValueKey('workbench-loaded-name'),
          style: theme.textTheme.titleMedium,
        ),
        Text(
          s.workbenchInfo(
            rate,
            info.channels == 1 ? s.workbenchMono : s.workbenchStereo,
            formatClock(info.duration),
          ),
          key: const ValueKey('workbench-info'),
        ),
        Text(s.workbenchBackupNote, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        WorkbenchWaveform(key: ObjectKey(c.reader), controller: c),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: const ValueKey('workbench-play'),
              onPressed: () => unawaited(c.togglePlay()),
              icon: Icon(c.playbackActive ? Icons.stop : Icons.play_arrow),
              label: Text(c.playbackActive ? s.workbenchStop : s.workbenchPlay),
            ),
            FilterChip(
              label: Text(s.workbenchLoop),
              selected: c.loop,
              onSelected: c.playbackActive ? null : c.setLoop,
            ),
            OutlinedButton.icon(
              key: const ValueKey('workbench-save'),
              onPressed: _training == null || _mediaBusy ? null : _save,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(s.workbenchSave),
            ),
          ],
        ),
        if (c.positionOf(c.end - c.start) > WorkbenchController.maxPlay)
          Text(s.workbenchPlayLimit, style: theme.textTheme.bodySmall),
        const Divider(height: 32),
        WorkbenchDecodePanel(controller: c, training: _training),
      ],
    );
  }
}
