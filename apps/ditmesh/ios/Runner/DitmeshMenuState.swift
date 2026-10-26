/// State published by Dart. A reply may request revalidation, but never owns
/// enabled state or changes the owner of an already queued invocation.
final class DitmeshMenuState {
  struct Invocation {
    let command: String
    let owner: String
    fileprivate let revision: UInt64

    var arguments: [String: String] { ["command": command, "owner": owner] }
  }

  private(set) var enabled = false
  private var owner = ""
  private var revision: UInt64 = 0

  func update(enabled: Bool, owner: String) {
    revision &+= 1
    self.enabled = enabled && !owner.isEmpty
    self.owner = owner
  }

  func begin(_ command: String) -> Invocation? {
    guard enabled, command == "search" || command == "contacts" else { return nil }
    return Invocation(command: command, owner: owner, revision: revision)
  }

  func needsRefresh(after response: Any?, for invocation: Invocation) -> Bool {
    // A newer update supersedes this reply. Even a current refusal only asks
    // UIKit to revalidate; Dart publishes the authoritative enabled state.
    return invocation.revision == revision && (response as? Bool) != true
  }
}
