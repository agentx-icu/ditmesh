import 'dart:math';

import '../drill.dart';
import 'training_material.dart';

/// Drills a [TrainingMaterial]: text segments in order, list entries
/// sampled randomly (seeded). With [allowed] only items made of those
/// symbols are used (learned-only practice).
final class MaterialDrill implements DrillGenerator {
  MaterialDrill(this.material, {Set<String>? allowed})
    : items = allowed == null
          ? material.normalizedItems
          : material.itemsWithin(allowed);

  final TrainingMaterial material;

  /// The usable items; empty means the drill cannot run.
  final List<String> items;
  int _next = 0;

  bool get canGenerate => items.isNotEmpty;

  @override
  String get kind => 'material';

  @override
  Drill generate(Random random) {
    if (items.isEmpty) throw StateError('no usable items');
    final String text;
    if (material.kind == MaterialKind.text) {
      text = items[_next % items.length];
      _next++;
    } else {
      text = items[random.nextInt(items.length)];
    }
    return Drill.fromText(text, kind: kind);
  }
}
