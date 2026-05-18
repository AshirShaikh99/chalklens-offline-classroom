import Cocoa
import FlutterMacOS
import PDFKit
import Vision

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    TextRecognitionChannel.register(with: flutterViewController)

    super.awakeFromNib()
  }
}

private enum TextRecognitionChannel {
  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "chalk_lens/text_recognition",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "recognizeTextFile":
        recognizeTextFile(call, result)
      case "extractPdfTextFile":
        extractPdfTextFile(call, result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func recognizeTextFile(
    _ call: FlutterMethodCall,
    _ result: @escaping FlutterResult
  ) {
    guard
      let args = call.arguments as? [String: Any],
      let path = args["path"] as? String,
      !path.isEmpty
    else {
      result(FlutterError(
        code: "invalidArguments",
        message: "Image path is required.",
        details: nil
      ))
      return
    }

    let url = URL(fileURLWithPath: path)
    DispatchQueue.global(qos: .userInitiated).async {
      let didStartSecurityScope = url.startAccessingSecurityScopedResource()
      defer {
        if didStartSecurityScope {
          url.stopAccessingSecurityScopedResource()
        }
      }

      var didReturn = false
      let request = VNRecognizeTextRequest { request, error in
        guard !didReturn else { return }
        didReturn = true

        if let error {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "recognitionFailed",
              message: error.localizedDescription,
              details: nil
            ))
          }
          return
        }

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let lines = observations
          .sorted(by: readingOrder)
          .compactMap { observation in
            observation.topCandidates(1).first?.string
              .trimmingCharacters(in: .whitespacesAndNewlines)
          }
          .filter { !$0.isEmpty }

        DispatchQueue.main.async {
          result(lines.joined(separator: "\n"))
        }
      }

      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true

      do {
        try VNImageRequestHandler(url: url, options: [:]).perform([request])
      } catch {
        guard !didReturn else { return }
        didReturn = true
        DispatchQueue.main.async {
          result(FlutterError(
            code: "recognitionFailed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private static func extractPdfTextFile(
    _ call: FlutterMethodCall,
    _ result: @escaping FlutterResult
  ) {
    guard
      let args = call.arguments as? [String: Any],
      let path = args["path"] as? String,
      !path.isEmpty
    else {
      result(FlutterError(
        code: "invalidArguments",
        message: "PDF path is required.",
        details: nil
      ))
      return
    }

    let url = URL(fileURLWithPath: path)
    DispatchQueue.global(qos: .userInitiated).async {
      let didStartSecurityScope = url.startAccessingSecurityScopedResource()
      defer {
        if didStartSecurityScope {
          url.stopAccessingSecurityScopedResource()
        }
      }

      guard let document = PDFDocument(url: url) else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "pdfOpenFailed",
            message: "Could not open the selected PDF.",
            details: nil
          ))
        }
        return
      }

      var pages: [String] = []
      for index in 0..<document.pageCount {
        guard let page = document.page(at: index) else { continue }
        let pageText = page.string?
          .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !pageText.isEmpty {
          pages.append(pageText)
        }
      }

      DispatchQueue.main.async {
        result(pages.joined(separator: "\n\n"))
      }
    }
  }

  private static func readingOrder(
    _ lhs: VNRecognizedTextObservation,
    _ rhs: VNRecognizedTextObservation
  ) -> Bool {
    let rowTolerance = 0.02
    let lhsY = lhs.boundingBox.midY
    let rhsY = rhs.boundingBox.midY
    if abs(lhsY - rhsY) > rowTolerance {
      return lhsY > rhsY
    }
    return lhs.boundingBox.minX < rhs.boundingBox.minX
  }
}
