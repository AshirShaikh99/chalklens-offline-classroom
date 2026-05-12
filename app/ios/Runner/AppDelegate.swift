import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var voiceRecorder: AVAudioRecorder?
  private var voiceRecordingURL: URL?

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

    let audioChannel = FlutterMethodChannel(
      name: "chalk_lens/audio_recorder",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    audioChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "start":
        self?.startVoiceRecording(result)
      case "stop":
        self?.stopVoiceRecording(result)
      case "cancel":
        self?.cancelVoiceRecording(result)
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

  private func startVoiceRecording(_ result: @escaping FlutterResult) {
    if voiceRecorder != nil {
      result(FlutterError(
        code: "alreadyRecording",
        message: "Voice recording is already running.",
        details: nil
      ))
      return
    }

    let session = AVAudioSession.sharedInstance()
    session.requestRecordPermission { [weak self] allowed in
      DispatchQueue.main.async {
        guard let self else { return }
        guard allowed else {
          result(FlutterError(
            code: "permissionDenied",
            message: "Microphone permission was denied.",
            details: nil
          ))
          return
        }

        do {
          try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker]
          )
          try session.setActive(true)

          let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("chalk_lens_voice_\(UUID().uuidString).wav")
          let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
          ]
          let recorder = try AVAudioRecorder(url: url, settings: settings)
          recorder.prepareToRecord()
          guard recorder.record() else {
            throw NSError(
              domain: "ChalkLensAudio",
              code: 1,
              userInfo: [NSLocalizedDescriptionKey: "Recorder did not start."]
            )
          }

          self.voiceRecordingURL = url
          self.voiceRecorder = recorder
          result(nil)
        } catch {
          try? session.setActive(false, options: .notifyOthersOnDeactivation)
          result(FlutterError(
            code: "recorderUnavailable",
            message: "Microphone recorder could not start.",
            details: "\(error)"
          ))
        }
      }
    }
  }

  private func stopVoiceRecording(_ result: FlutterResult) {
    guard let recorder = voiceRecorder else {
      result(FlutterError(
        code: "notRecording",
        message: "No voice recording is active.",
        details: nil
      ))
      return
    }

    let url = voiceRecordingURL ?? recorder.url
    recorder.stop()
    voiceRecorder = nil
    voiceRecordingURL = nil
    try? AVAudioSession.sharedInstance().setActive(
      false,
      options: .notifyOthersOnDeactivation
    )

    do {
      let data = try Data(contentsOf: url)
      try? FileManager.default.removeItem(at: url)
      if data.isEmpty {
        result(FlutterError(
          code: "emptyRecording",
          message: "No voice was recorded.",
          details: nil
        ))
        return
      }
      result(FlutterStandardTypedData(bytes: data))
    } catch {
      result(FlutterError(
        code: "emptyRecording",
        message: "No voice recording was returned.",
        details: "\(error)"
      ))
    }
  }

  private func cancelVoiceRecording(_ result: FlutterResult) {
    let url = voiceRecordingURL ?? voiceRecorder?.url
    voiceRecorder?.stop()
    voiceRecorder = nil
    voiceRecordingURL = nil
    if let url {
      try? FileManager.default.removeItem(at: url)
    }
    try? AVAudioSession.sharedInstance().setActive(
      false,
      options: .notifyOthersOnDeactivation
    )
    result(nil)
  }
}
