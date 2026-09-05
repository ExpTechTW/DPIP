import AVFoundation
import Flutter

/// Speaks a short phrase and reports when it has finished, for the foreground
/// EEW announcement that must complete before the warning sound plays.
///
/// `AVSpeechSynthesizer` directly rather than a package: the only pub package
/// with this API ships no Swift Package Manager support, and this app builds
/// without CocoaPods.
///
/// One utterance at a time. A `speak` while another is in flight cancels it,
/// and the cancelled call still returns normally — the caller's contract is
/// latest-report-wins, so a superseded phrase is the expected path rather than
/// an error. Every `speak` replies exactly once, which the channel requires.
public class SpeechPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/speech",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SpeechPlugin(), channel: channel)
  }

  private let synthesizer = AVSpeechSynthesizer()
  private var pending: FlutterResult?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  public func handle(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    switch call.method {
    case "speak":
      guard let arguments = call.arguments as? [String: Any],
        let text = arguments["text"] as? String,
        let language = arguments["language"] as? String
      else {
        result(
          FlutterError(
            code: "BAD_ARGUMENTS", message: "speak needs text and language", details: nil))
        return
      }
      speak(text, language: language, result: result)
    case "stop":
      synthesizer.stopSpeaking(at: .immediate)
      settle()
      deactivateSession()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func speak(_ text: String, language: String, result: @escaping FlutterResult) {
    // Supersede first, so the previous call is answered before this one can
    // take its place — `didCancel` for it would otherwise settle *this* result.
    synthesizer.stopSpeaking(at: .immediate)
    settle()

    // The default category follows the Silent switch. A foreground disaster
    // announcement has to stay audible there too; `.playback` with
    // `.voicePrompt` and `duckOthers` keeps it intelligible without taking
    // ownership of another app's audio for longer than the phrase lasts.
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
    try? session.setActive(true)

    let utterance = AVSpeechUtterance(string: text)
    // A language the device has no voice for leaves the system default in
    // place: a phrase in the wrong accent still carries the intensity, and
    // silence does not.
    if let voice = AVSpeechSynthesisVoice(language: language) {
      utterance.voice = voice
    }
    // Loudest within the user's media volume. Changing the device volume would
    // be intrusive and would outlast the warning, so that stays theirs.
    utterance.volume = 1.0

    pending = result
    synthesizer.speak(utterance)
  }

  private func settle() {
    guard let result = pending else { return }
    pending = nil
    result(nil)
  }

  private func deactivateSession() {
    try? AVAudioSession.sharedInstance().setActive(
      false, options: [.notifyOthersOnDeactivation])
  }

  public func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
  ) {
    settle()
    deactivateSession()
  }

  public func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance
  ) {
    settle()
  }
}
