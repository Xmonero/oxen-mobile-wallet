import Flutter
import UIKit

public class SwiftQueneroCoinPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "quenero_coin", binaryMessenger: registrar.messenger())
        let instance = SwiftQueneroCoinPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
