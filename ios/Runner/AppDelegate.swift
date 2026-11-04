import CoreTelephony
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "barqody/device_country",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getCountryIso":
        result(Self.resolveCellularCountryIso())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Carrier ISO when a SIM / eSIM is present; nil on Wi‑Fi-only devices.
  private static func resolveCellularCountryIso() -> String? {
    let info = CTTelephonyNetworkInfo()
    let carriers = info.serviceSubscriberCellularProviders?.values ?? []
    for carrier in carriers {
      if let iso = carrier.isoCountryCode?.trimmingCharacters(in: .whitespacesAndNewlines),
         iso.count == 2 {
        return iso.uppercased()
      }
    }
    return nil
  }
}
