import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Make the UIWindow background transparent so the iOS safe area zone
    // (home indicator area) doesn't paint a white/black strip behind Flutter.
    window?.backgroundColor = UIColor.clear
    return result
  }
}
