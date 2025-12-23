import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // CRITICAL: Register plugins BEFORE calling super
    // This ensures plugins are ready when Flutter initializes
    GeneratedPluginRegistrant.register(with: self)
    
    // Then call super to complete initialization
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}