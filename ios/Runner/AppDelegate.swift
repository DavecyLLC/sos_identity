import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    // ✅ IMPORTANT: must return super or plugins can crash at startup
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
