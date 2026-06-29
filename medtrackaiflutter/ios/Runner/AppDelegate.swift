import Flutter
import UIKit
import flutter_local_notifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: self)
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(name: "com.medtrackai.widget",
                                                binaryMessenger: controller.binaryMessenger)
      widgetChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "syncData" {
          if let args = call.arguments as? [String: Any],
             let userDefaults = UserDefaults(suiteName: "group.com.medtrackai") {
              userDefaults.set(args["streak"], forKey: "streak")
              userDefaults.set(args["nextMedName"], forKey: "nextMedName")
              userDefaults.set(args["nextMedTime"], forKey: "nextMedTime")
              userDefaults.set(args["mascotMood"], forKey: "mascotMood")
              if #available(iOS 14.0, *) {
                  WidgetCenter.shared.reloadAllTimelines()
              }
              result(true)
          } else {
              result(FlutterError(code: "UNAVAILABLE", message: "UserDefaults not available", details: nil))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
