import Flutter
import UIKit

/// ditmesh overlay: the generated plugin registrant needs this class to
/// exist; ditmesh never uses the method channel (everything goes through
/// libtim2tox_ffi via dart:ffi), so registration is a no-op.
public class TencentCloudChatSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {}

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
