import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "chalk_lens/storage",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "availableStorageBytes":
        result(Self.availableStorageBytes())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func availableStorageBytes() -> Int64? {
    guard let url = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).first else {
      return nil
    }

    do {
      let values = try url.resourceValues(forKeys: [
        .volumeAvailableCapacityForImportantUsageKey,
        .volumeAvailableCapacityKey,
      ])
      if let capacity = values.volumeAvailableCapacityForImportantUsage {
        return capacity
      }
      if let capacity = values.volumeAvailableCapacity {
        return Int64(capacity)
      }
      return nil
    } catch {
      return nil
    }
  }
}
