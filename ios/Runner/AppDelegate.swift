import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBr3hQE4DvdH6bye1wJE4UM5YFG8KhDmAw")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  if let apiKey = dotenv.get("GOOGLE_MAPS_API_KEY") {
      // Set the API key for Google Maps SDK
      GMSServices.provideAPIKey(apiKey)
    }

} 