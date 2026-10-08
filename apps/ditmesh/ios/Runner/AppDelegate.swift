import Flutter
import UIKit
import UserNotifications
import Network

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let networkPath = DitmeshNetworkPathChannel()

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
    registerBackgroundTaskChannel(messenger)
    registerBackupExclusionChannel(messenger)
  }

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
