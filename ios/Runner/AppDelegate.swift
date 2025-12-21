import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Call super FIRST to ensure Flutter is initialized
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Then register plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return result
  }
}