part of 'nearby_service.dart';

extension _NearbyServiceCells on NearbyService {
  void _onEvent(RendezvousEvent e) {
    if (!running) return;
    if (!_cellByChatId.containsKey(e.chatIdHex)) return; // not one of ours
    switch (e) {
      case RendezvousJoined():
        _joinedChatIds.add(e.chatIdHex);
        // A successful join clears an earlier "full" / "unavailable" of the
        // same cell, so neither the precision-6 overflow cell nor the
        // unavailable state outlives the recovery.
        final joinedCell = _cellByChatId[e.chatIdHex];
        if (joinedCell != null) {
          _planner.clearFull(joinedCell);
          _unavailableCells.remove(joinedCell);
        }
        // Joined is joined, whatever stage the planner was in (a cell can
        // answer before the first fix's planning finished).
        _setStatus(NearbyStatus.active);
        unawaited(_broadcastPresence());
        _notify();
      case RendezvousLeft():
        _joinedChatIds.remove(e.chatIdHex);
        _dropPeersOfCell(e.chatIdHex);
        if (e.reason == 'full') {
          final cell = _cellByChatId[e.chatIdHex];
          if (cell != null) _planner.markFull(cell);
        } else if (e.reason == 'failed' ||
            e.reason == 'kicked' ||
            e.reason == 'stale') {
          // The native side backs off and retries by itself; the UI only
          // needs to know the cell is not available right now.
          final cell = _cellByChatId[e.chatIdHex];
          if (cell != null) _unavailableCells.add(cell);
          // Nothing joined and at least one cell failing: say so (plan §3.1
          // "unavailable for 10 min and the UI says so").
          if (_joinedChatIds.isEmpty && _unavailableCells.isNotEmpty) {
            _setStatus(NearbyStatus.cellUnavailable);
          }
        }
        _notify();
      case RendezvousPeer():
        if (e.joined) {
          final last = _lastPeerJoinPresence;
          final now = _clock();
          if (last == null ||
              now.difference(last) >= NearbyService.presenceOnPeerJoinMinGap) {
            _lastPeerJoinPresence = now;
            unawaited(_broadcastPresence());
          }
        } else {
          _forgetNgcPeer(e.peerPkHex, e.chatIdHex);
          _notify();
        }
      case RendezvousPeersChanged():
        _notify();
      case RendezvousFull():
        final cell = _cellByChatId[e.chatIdHex];
        if (cell != null) _planner.markFull(cell);
      case RendezvousPacket():
        unawaited(_onPacket(e));
    }
  }
}
