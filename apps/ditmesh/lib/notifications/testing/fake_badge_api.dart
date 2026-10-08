import '../badge_api.dart';

/// Recording [BadgeApi] for tests.
final class FakeBadgeApi implements BadgeApi {
  FakeBadgeApi({this.supported = true});

  bool supported;

  /// Every value written, in order.
  final List<int> writes = <int>[];

  int supportChecks = 0;

  /// The badge as the OS would show it now; null before the first write.
  int? get current => writes.isEmpty ? null : writes.last;

  @override
  Future<bool> isSupported() async {
    supportChecks++;
    return supported;
  }

  @override
  Future<void> update(int count) async {
    writes.add(count);
  }
}
