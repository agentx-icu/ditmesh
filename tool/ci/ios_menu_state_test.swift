import Foundation

@main
enum IosMenuStateTest {
  static func main() {
    let state = DitmeshMenuState()
    precondition(state.begin("search") == nil)
    state.update(enabled: true, owner: "")
    precondition(!state.enabled)
    state.update(enabled: true, owner: "old-session")
    precondition(state.begin("sideTone") == nil)
    let old = state.begin("search")!
    precondition(old.arguments == ["command": "search", "owner": "old-session"])

    // A current refusal revalidates, but it cannot latch enabled=false. The
    // Dart side owns availability and will publish any necessary change.
    precondition(state.needsRefresh(after: false, for: old))
    precondition(state.enabled)
    precondition(state.needsRefresh(after: NSError(domain: "test", code: 1), for: old))
    precondition(state.enabled)
    precondition(!state.needsRefresh(after: true, for: old))

    // Reproduce the old race: a new false/true update arrives before an old
    // failed/error reply. The reply cannot undo the newer enabled state.
    state.update(enabled: false, owner: "old-session")
    state.update(enabled: true, owner: "new-session")
    precondition(old.arguments["owner"] == "old-session")
    precondition(!state.needsRefresh(after: false, for: old))
    precondition(!state.needsRefresh(after: NSError(domain: "test", code: 2), for: old))
    precondition(state.enabled)
    let current = state.begin("contacts")!
    precondition(current.arguments == ["command": "contacts", "owner": "new-session"])

    state.update(enabled: false, owner: "")
    precondition(state.begin("contacts") == nil)
    precondition(!state.needsRefresh(after: false, for: current))
    print("iOS menu state: ownership, current/late false/error replies and teardown passed")
  }
}
