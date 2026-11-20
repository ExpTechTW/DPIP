import CoreMotion
import Flutter
import Foundation

/// Streams the accelerometer at about 50 Hz on `com.exptech.dpip/accelerometer`,
/// flushed on the main thread about every 100 ms.
///
/// Each batch is host-endian float64 groups of `timestampNanos, x, y, z`. An
/// interval with no samples sends nothing. Acceleration is gal.
/// `CMAccelerometerData.timestamp` is seconds since boot and is converted to
/// nanoseconds.
///
/// Core Motion reports acceleration in g with the opposite sign from Android:
/// a phone at rest, flat, screen up, reads about (0, 0, -1), and the same
/// pose with the top of the phone pointing up reads about (0, -1, 0). All
/// three components are negated and multiplied by 980.665, so the frame
/// matches Android — +x to the right, +y toward the top of the device, +z
/// out of the screen, and z ≈ +980 gal at rest with the screen up. Axes stay
/// in that device frame; they are not rotated with the interface orientation.
///
/// Samples arrive on a private queue and are flushed from a main-run-loop
/// timer. Cancelling stops updates and the timer. When the accelerometer
/// cannot start, `onListen` returns `FlutterError` code `unavailable`.
public class AccelerometerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  /// 1 g = 9.80665 m/s² = 980.665 gal.
  private static let galsPerG = 980.665 
  private static let sampleInterval: TimeInterval = 0.02
  private static let flushInterval: TimeInterval = 0.1

  private let motion = CMMotionManager()
  private let samplesQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "com.exptech.dpip.accelerometer"
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .userInitiated
    return queue
  }()
  private let lock = NSLock()
  private var samples: [Double] = []
  private var listening = false
  private var sink: FlutterEventSink?
  private var timer: Timer?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(
      name: "com.exptech.dpip/accelerometer",
      binaryMessenger: registrar.messenger())
    channel.setStreamHandler(AccelerometerPlugin())
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    stopUpdates()
    guard motion.isAccelerometerAvailable else {
      return FlutterError(
        code: "unavailable",
        message: "Accelerometer not available",
        details: nil)
    }
    sink = events
    lock.lock()
    listening = true
    samples.removeAll(keepingCapacity: true)
    lock.unlock()

    motion.accelerometerUpdateInterval = Self.sampleInterval
    motion.startAccelerometerUpdates(to: samplesQueue) { [weak self] data, error in
      guard let self, error == nil, let data else { return }
      let acceleration = data.acceleration
      // Negated so the sign matches Android. See the type comment.
      let x = -acceleration.x * Self.galsPerG
      let y = -acceleration.y * Self.galsPerG
      let z = -acceleration.z * Self.galsPerG
      let timestampNanos = data.timestamp * 1_000_000_000
      self.lock.lock()
      if self.listening {
        self.samples.append(contentsOf: [timestampNanos, x, y, z])
      }
      self.lock.unlock()
    }

    let timer = Timer(timeInterval: Self.flushInterval, repeats: true) { [weak self] timer in
      guard let self else {
        timer.invalidate()
        return
      }
      self.flush()
    }
    // `.common` so a tracking touch does not hold the batch until the gesture ends.
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopUpdates()
    return nil
  }

  private func stopUpdates() {
    motion.stopAccelerometerUpdates()
    timer?.invalidate()
    timer = nil
    lock.lock()
    listening = false
    samples.removeAll(keepingCapacity: true)
    lock.unlock()
    sink = nil
  }

  /// Sends the samples taken since the previous flush. Runs on the main thread.
  private func flush() {
    lock.lock()
    let batch = samples
    samples.removeAll(keepingCapacity: true)
    let active = listening
    lock.unlock()
    guard active, !batch.isEmpty, let sink else { return }
    let bytes = batch.withUnsafeBufferPointer { Data(buffer: $0) }
    sink(FlutterStandardTypedData(float64: bytes))
  }
}
