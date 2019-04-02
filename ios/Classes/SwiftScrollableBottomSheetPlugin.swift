import Flutter
import UIKit

public class SwiftScrollableBottomSheetPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "scrollable_bottom_sheet", binaryMessenger: registrar.messenger())
    let instance = SwiftScrollableBottomSheetPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
