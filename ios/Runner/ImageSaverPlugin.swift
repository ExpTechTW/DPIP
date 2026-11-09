import Flutter
import Photos
import UIKit

/// Saves encoded image bytes into the photo library — the counterpart of
/// Android's `ImageSaverChannel`, with the same channel name and protocol.
///
/// The bytes are the ones the app already fetched (the CWA report image), so
/// nothing here downloads anything. Add-only access is what a "save" needs:
/// the app never reads the library, so iOS shows the narrower grant and never
/// asks for full photo access.
///
/// The asset is created from data rather than from a temporary file: the
/// filename still reaches the library through `originalFilename`, and no
/// cleanup path has to be remembered if the write fails halfway.
public class ImageSaverPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/image_saver",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ImageSaverPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "save":
      save(call.arguments as? [String: Any] ?? [:], result: result)
    case "status":
      result(statusName(PHPhotoLibrary.authorizationStatus(for: .addOnly)))
    case "request":
      // Asked once by the Dart side before a save; iOS never prompts twice, so
      // a `denied` answer here is final and the UI offers Settings instead.
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        DispatchQueue.main.async { result(self.statusName(status)) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func statusName(_ status: PHAuthorizationStatus) -> String {
    switch status {
    case .authorized, .limited:
      return "granted"
    case .denied, .restricted:
      return "denied"
    default:
      return "notDetermined"
    }
  }

  private func save(_ args: [String: Any], result: @escaping FlutterResult) {
    guard
      let payload = args["bytes"] as? FlutterStandardTypedData,
      let fileName = args["fileName"] as? String,
      !fileName.isEmpty
    else {
      result(
        FlutterError(
          code: "invalid_args", message: "bytes and fileName are required", details: nil))
      return
    }
    let data = payload.data

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        // A refusal is not a failure to report as "try again": the only way
        // forward is Settings, and the Dart side says exactly that.
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "permission_denied", message: "Photo library access was refused",
              details: nil))
        }
        return
      }

      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetCreationRequest.forAsset()
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = fileName
        request.addResource(with: .photo, data: data, options: options)
      }) { success, error in
        // The completion handler runs off the main thread; Flutter's reply
        // belongs to the platform thread.
        DispatchQueue.main.async {
          if success {
            result(nil)
          } else {
            result(
              FlutterError(
                code: "save_failed",
                message: error?.localizedDescription ?? "The image could not be saved",
                details: nil))
          }
        }
      }
    }
  }
}
