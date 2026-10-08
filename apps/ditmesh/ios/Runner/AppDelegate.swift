import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
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
