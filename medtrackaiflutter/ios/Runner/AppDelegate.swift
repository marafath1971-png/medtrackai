import Flutter
import UIKit
import flutter_local_notifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Retained: a FlutterMethodChannel does not keep itself alive, and a
  /// deallocated channel stops delivering calls to its handler.
  private var widgetChannel: FlutterMethodChannel?

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
    
    // Register on the shared engine's messenger, not window?.rootViewController.
    // Under the UIScene lifecycle (this app has a SceneDelegate and a
    // UIApplicationSceneManifest) the window is still nil here — the scene
    // creates it later — so the old `if let controller = window?...` guard
    // silently failed and the channel was never registered, leaving every
    // syncData call to throw MissingPluginException.
    if let registrar = self.registrar(forPlugin: "MedTrackAIWidget") {
      widgetChannel = FlutterMethodChannel(name: "com.medtrackai.widget",
                                           binaryMessenger: registrar.messenger())
      widgetChannel?.setMethodCallHandler({
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
