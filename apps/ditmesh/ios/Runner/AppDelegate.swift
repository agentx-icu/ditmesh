import Flutter
import UIKit
import UserNotifications
import Network

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let networkPath = DitmeshNetworkPathChannel()
  let menuCommands = DitmeshMenuChannel()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: taps and foreground presentation on iOS
    // are delivered through the app delegate (FlutterAppDelegate already
    // conforms to UNUserNotificationCenterDelegate). See
    // lib/notifications/README.md.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    networkPath.register(binaryMessenger: messenger)
    menuCommands.register(binaryMessenger: messenger)
    registerBackgroundTaskChannel(messenger)
    registerBackupExclusionChannel(messenger)
  }

  override func buildMenu(with builder: UIMenuBuilder) {
    super.buildMenu(with: builder)
    guard #available(iOS 26.0, *), UIDevice.current.userInterfaceIdiom == .pad,
      builder.system == UIMenuSystem.main,
      let menu = menuCommands.menu(search: #selector(searchFromMenu(_:)),
                                   contacts: #selector(contactsFromMenu(_:)))
    else { return }
    builder.remove(menu: DitmeshMenuChannel.identifier)
    builder.insertSibling(menu, afterMenu: .edit)
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(searchFromMenu(_:)) || action == #selector(contactsFromMenu(_:)) {
      return menuCommands.canInvoke
    }
    return super.canPerformAction(action, withSender: sender)
  }

  override func validate(_ command: UICommand) {
    super.validate(command)
    if command.action == #selector(searchFromMenu(_:)) || command.action == #selector(contactsFromMenu(_:)) {
      if menuCommands.canInvoke { command.attributes.remove(.disabled) }
      else { command.attributes.insert(.disabled) }
    }
  }

  @objc private func searchFromMenu(_ sender: UICommand) { menuCommands.invoke("search") }
  @objc private func contactsFromMenu(_ sender: UICommand) { menuCommands.invoke("contacts") }

  // MARK: - Backup exclusion (packages/ditmesh_chat backup_exclusion.dart)
  //
  // Application Support is backed up to iCloud / Finder by default, and the
  // identity tree holds the Tox private key. Dart marks the identity
  // directory (it must already exist) with isExcludedFromBackup, which also
  // covers everything later created inside it.

  private func registerBackupExclusionChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "icu.agentx.ditmesh/backup_exclusion", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let path = call.arguments as? String, !path.isEmpty else {
        result(FlutterError(
          code: "INVALID_ARGS", message: "Expected a directory path", details: nil))
        return
      }
      var isDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
        isDirectory.boolValue
      else {
        result(FlutterError(
          code: "NOT_FOUND", message: "No directory at \(path)", details: nil))
        return
      }
      var url = URL(fileURLWithPath: path, isDirectory: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(
          code: "SET_FAILED", message: error.localizedDescription, details: nil))
      }
    }
  }

  // MARK: - Background task bridge (lib/lifecycle/background_task_api.dart)
  //
  // iOS suspends the app a few seconds after it is backgrounded. Dart's
  // AppLifecycleCoordinator holds a beginBackgroundTask assertion for its
  // background budget so the durability flush and in-flight sends finish.
  // Tokens are ours (not the raw UIBackgroundTaskIdentifier) so a late
  // "end" for a task that already expired is a harmless no-op.

  private var backgroundTasks: [Int: UIBackgroundTaskIdentifier] = [:]
  private var nextBackgroundTaskToken = 0

  private func registerBackgroundTaskChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "icu.agentx.ditmesh/background_task", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "begin":
        result(self.beginBackgroundTask())
      case "end":
        if let token = call.arguments as? Int {
          self.endBackgroundTask(token)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func beginBackgroundTask() -> Int? {
    nextBackgroundTaskToken += 1
    let token = nextBackgroundTaskToken
    let id = UIApplication.shared.beginBackgroundTask(withName: "DitMesh flush") {
      [weak self] in
      // Out of time: end it ourselves or iOS terminates the app.
      self?.endBackgroundTask(token)
    }
    if id == .invalid { return nil }
    backgroundTasks[token] = id
    return token
  }

  private func endBackgroundTask(_ token: Int) {
    guard let id = backgroundTasks.removeValue(forKey: token) else { return }
    UIApplication.shared.endBackgroundTask(id)
  }
}

/// One engine and the existing single scene. UICommand is deliberately keyless
/// so a keyboard press cannot dispatch through both UIKit and Flutter.
final class DitmeshMenuChannel {
  static let identifier = UIMenu.Identifier("icu.agentx.ditmesh.chat")
  private var channel: FlutterMethodChannel?
  private var labels: (title: String, search: String, contacts: String)?
  private let state = DitmeshMenuState()
  private weak var scene: UIWindowScene?

  var canInvoke: Bool {
    guard #available(iOS 26.0, *), UIDevice.current.userInterfaceIdiom == .pad,
      state.enabled, let scene, scene.activationState == .foregroundActive,
      let window = scene.windows.first(where: { $0.isKeyWindow }), !window.isHidden,
      window.rootViewController?.presentedViewController == nil,
      !hasTextInputResponder(window)
    else { return false }
    let active = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
    return active.count == 1 && active.first === scene
  }

  private func hasTextInputResponder(_ view: UIView) -> Bool {
    if view.isFirstResponder && view is UITextInput { return true }
    return view.subviews.contains(where: hasTextInputResponder)
  }

  func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "icu.agentx.ditmesh/menu_commands", binaryMessenger: binaryMessenger)
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update" else { result(FlutterMethodNotImplemented); return }
      guard let self, let data = call.arguments as? [String: Any],
        let title = data["title"] as? String, !title.isEmpty,
        let search = data["search"] as? String, !search.isEmpty,
        let contacts = data["contacts"] as? String, !contacts.isEmpty,
        let enabled = data["enabled"] as? Bool,
        let owner = data["owner"] as? String, !enabled || !owner.isEmpty
      else {
        result(FlutterError(code: "INVALID_MENU", message: "Invalid menu state", details: nil))
        return
      }
      self.labels = (title, search, contacts)
      self.state.update(enabled: enabled, owner: owner)
      self.refresh()
      result(true)
    }
  }

  func setScene(_ scene: UIScene, active: Bool) {
    if active { self.scene = scene as? UIWindowScene }
    else if self.scene === scene { self.scene = nil }
    refresh()
  }

  private func refresh() {
    guard #available(iOS 26.0, *), UIDevice.current.userInterfaceIdiom == .pad else { return }
    // UIMenuSystem.main is UIMainMenuSystem.shared, retaining UIKit's menus.
    UIMenuSystem.main.setNeedsRebuild()
    UIMenuSystem.main.setNeedsRevalidate()
  }

  func menu(search: Selector, contacts: Selector) -> UIMenu? {
    guard let labels else { return nil }
    let attributes: UIMenuElement.Attributes = canInvoke ? [] : [.disabled]
    return UIMenu(title: labels.title, identifier: Self.identifier, children: [
      UICommand(title: labels.search, action: search, attributes: attributes),
      UICommand(title: labels.contacts, action: contacts, attributes: attributes),
    ])
  }

  func invoke(_ command: String) {
    guard canInvoke, let invocation = state.begin(command) else { return }
    channel?.invokeMethod("invoke", arguments: invocation.arguments) { [weak self] response in
      // Dart revalidates route/focus/readiness at invocation, closing a stale
      // menu-state race. A delayed response cannot overwrite a newer update.
      guard let self else { return }
      if self.state.needsRefresh(after: response, for: invocation) { self.refresh() }
    }
  }
}

// Reports the current mobile network path to the bootstrap policy.
final class DitmeshNetworkPathChannel: NSObject, FlutterStreamHandler {
  private let queue = DispatchQueue(label: "ditmesh.network_path")
  private var channel: FlutterEventChannel?
  private var generation = 0
  private var monitor: NWPathMonitor?
  private var sink: FlutterEventSink?
  private var lastSent: (Bool, String?)?

  func register(binaryMessenger: FlutterBinaryMessenger) {
    _ = onCancel(withArguments: nil)
    channel?.setStreamHandler(nil)
    let channel = FlutterEventChannel(name: "ditmesh/network_path", binaryMessenger: binaryMessenger)
    channel.setStreamHandler(self)
    self.channel = channel
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    _ = onCancel(withArguments: nil)
    let ticket = generation
    sink = events
    lastSent = nil
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      let available = path.status == .satisfied
      let identity = available ? DitmeshNetworkPathChannel.identity(of: path) : nil
      DispatchQueue.main.async { [weak self] in
        guard let self, self.generation == ticket else { return }
        self.emit(available: available, identity: identity)
      }
    }
    monitor.start(queue: queue)
    self.monitor = monitor
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    generation += 1
    monitor?.pathUpdateHandler = nil
    monitor?.cancel()
    monitor = nil
    sink = nil
    return nil
  }

  deinit { monitor?.cancel() }

  private func emit(available: Bool, identity: String?) {
    guard let sink else { return }
    if let last = lastSent, last.0 == available, last.1 == identity { return }
    lastSent = (available, identity)
    sink(["available": available, "identity": identity.map { $0 as Any } ?? NSNull()])
  }

  /// What the default path is USING: the interface types it routes over
  /// (`usesInterfaceType`, not merely the available list), the interfaces of
  /// those types with their current addresses, and the path's gateways — so a
  /// Wi-Fi <-> cellular handover, a new address, or a new router all change it.
  private static func identity(of path: NWPath) -> String {
    let kinds: [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet, .other]
    let used = kinds.filter { path.usesInterfaceType($0) }
    let interfaces = path.availableInterfaces
      .filter { iface in used.contains(iface.type) }
      .map { "\($0.name)=\(addresses(of: $0.name).joined(separator: ","))" }
      .sorted()
    let gateways = path.gateways.map { "\($0)" }.sorted()
    return "\(used.map { "\($0)" }.joined(separator: "+"))|"
      + "\(interfaces.joined(separator: ";"))|\(gateways.joined(separator: ","))"
  }

  /// Sorted numeric addresses (IPv4 + IPv6) currently on [name].
  private static func addresses(of name: String) -> [String] {
    var result: [String] = []
    var head: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&head) == 0, let first = head else { return result }
    defer { freeifaddrs(head) }
    var cursor: UnsafeMutablePointer<ifaddrs>? = first
    while let entry = cursor {
      defer { cursor = entry.pointee.ifa_next }
      guard String(cString: entry.pointee.ifa_name) == name,
        let addr = entry.pointee.ifa_addr
      else { continue }
      let family = Int32(addr.pointee.sa_family)
      guard family == AF_INET || family == AF_INET6 else { continue }
      var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
      let len = socklen_t(family == AF_INET ? MemoryLayout<sockaddr_in>.size : MemoryLayout<sockaddr_in6>.size)
      if getnameinfo(addr, len, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
        result.append(String(cString: host))
      }
    }
    return result.sorted()
  }
}
