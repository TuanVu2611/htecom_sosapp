import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var googleMapsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HcmuSosGoogleMaps") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "hcmu_sos/google_maps",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getApiKey" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String ?? "")
    }
    googleMapsChannel = channel
  }
}
