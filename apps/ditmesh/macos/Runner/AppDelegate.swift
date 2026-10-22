import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var activationChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      activationChannel = FlutterMethodChannel(name: "ditmesh/desktop_activation",
        binaryMessenger: controller.engine.binaryMessenger)
    }
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication,
      hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      mainFlutterWindow?.makeKeyAndOrderFront(nil)
      activationChannel?.invokeMethod("showWindow", arguments: nil)
    }
    return true
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
