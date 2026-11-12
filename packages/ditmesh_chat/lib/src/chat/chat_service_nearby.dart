part of 'tim2tox_chat_service.dart';

mixin _NearbyCapability implements NearbyTransportProvider {
  FfiChatService? get _service;
  ChatEngine get _engine;
  bool get _disposed;
  bool get _replacing;

  FfiChatService? _nearbySession;
  NearbyTransport? _nearbyTransport;

  @override
  NearbyTransport? get nearbyTransport {
    final service = _service;
    if (service == null || _disposed || _replacing) return null;
    if (!identical(service, _nearbySession)) {
      _nearbySession = service;
      _nearbyTransport = Tim2ToxNearbyTransport(
        service.rendezvous,
        isCurrent: () =>
            !_disposed &&
            !_replacing &&
            identical(_service, service) &&
            identical(_engine.service, service),
      );
    }
    return _nearbyTransport;
  }
}
