import 'dart:io';

/// Resolve outside synchronous FFI. Persist host text, never a DNS cache.
class BootstrapHostResolver {
  BootstrapHostResolver({
    Future<List<InternetAddress>> Function(String)? lookup,
    this.timeout = const Duration(seconds: 8),
  }) : _lookup = lookup ?? InternetAddress.lookup;
  final Future<List<InternetAddress>> Function(String) _lookup;
  final Duration timeout;
  Future<List<String>> addresses(String host) async {
    final numeric = InternetAddress.tryParse(host);
    if (numeric != null) return [numeric.address];
    try {
      final resolved = await _lookup(host).timeout(timeout);
      return resolved.map((address) => address.address).toSet().toList();
    } on Object {
      return const [];
    }
  }
}
