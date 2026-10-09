import 'package:flutter/material.dart';
import 'playback_timeline.dart';

/// Called only for visible text. The controls themselves use numeric labels.
class PlaybackWordText extends StatelessWidget {
  const PlaybackWordText({
    super.key,
    required this.text,
    this.activeWord,
    this.style,
  });
  final String text;
  final int? activeWord;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    if (activeWord == null) return SelectableText(text, style: style);
    final words = PlaybackTimeline.wordsFor(text);
    var word = 0;
    final spans = <TextSpan>[];
    for (final match in RegExp(r'\s+|\S+').allMatches(text)) {
      final token = match.group(0)!;
      final matched = word < words.length && token == words[word];
      spans.add(
        TextSpan(
          text: token,
          style: matched && word == activeWord
              ? TextStyle(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                )
              : null,
        ),
      );
      if (matched) word++;
    }
    return SelectableText.rich(TextSpan(children: spans), style: style);
  }
}
