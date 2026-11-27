import CoreMotion
import Flutter
import Foundation
import UIKit

/// Streams the accelerometer on `com.exptech.dpip/accelerometer` at no more
/// than one sample per 20 ms of sensor time — never above 50 Hz — flushed on
/// the main thread about every 100 ms.
///
/// `accelerometerUpdateInterval` is a request, not a contract: Core Motion can
/// deliver faster than asked, and unevenly. The seismometer runs on a 50 Hz
/// grid, so anything faster only costs channel traffic and makes the page's
/// raw-rate readout report Core Motion's choice instead of the rate the app
/// works at. `AccelerometerDecimator` keeps the first sample in each 20 ms slot
/// and drops the rest. It decimates rather than averages: averaging one
/// reading in some slots and two in others would be a filter whose response
/// changes with whatever rate the device picked, while a kept sample is a
/// reading the sensor really took, at the timestamp it carries. Spacing stays
/// irregular — Dart still interpolates onto the exact 20 ms grid and does all
/// the filtering.
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
  private var lastDelivery: TimeInterval = 0
  private var lastFlush: TimeInterval = 0
  private var lastTimestamp: Double?
  private var streamError: String?
  private var generation = 0
  private var decimator = AccelerometerDecimator()
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

  public override init() {
    super.init()
    NotificationCenter.default.addObserver(
      self, selector: #selector(didBecomeActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  @objc private func didBecomeActive() {
    lock.lock()
    lastDelivery = ProcessInfo.processInfo.systemUptime
    lastFlush = lastDelivery
    lock.unlock()
  }

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
    lastDelivery = ProcessInfo.processInfo.systemUptime
    lastFlush = lastDelivery
    streamError = nil
    let session = generation
    samples.removeAll(keepingCapacity: true)
    lock.unlock()

    motion.accelerometerUpdateInterval = Self.sampleInterval
    motion.startAccelerometerUpdates(to: samplesQueue) { [weak self] data, error in
      guard let self else { return }
      // Scaling and validation touch only `data`, so do them before taking the
      // lock: the callback runs at 50 Hz or more and flush takes the same lock
      // on the main thread, so the shorter the critical section the less a
      // flush ever waits on it.
      var timestampNanos = 0.0
      var x = 0.0
      var y = 0.0
      var z = 0.0
      var invalid = false
      if let data {
        let acceleration = data.acceleration
        // Negated so the sign matches Android. See the type comment.
        x = -acceleration.x * Self.galsPerG
        y = -acceleration.y * Self.galsPerG
        z = -acceleration.z * Self.galsPerG
        timestampNanos = data.timestamp * 1_000_000_000
        invalid = !timestampNanos.isFinite || timestampNanos < 0
          || !x.isFinite || !y.isFinite || !z.isFinite
      }
      self.lock.lock()
      defer { self.lock.unlock() }
      guard self.listening, self.generation == session else { return }
      if let error {
        self.streamError = error.localizedDescription
        return
      }
      guard data != nil else { return }
      guard !invalid else {
        self.streamError = "Accelerometer returned an invalid reading"
        return
      }
      if let previous = self.lastTimestamp, timestampNanos <= previous { return }
      // Recorded before decimation: a dropped sample still proves the sensor
      // is alive, and the stall check in `flush` must not read a decimated
      // stream as a stalled one.
      self.lastTimestamp = timestampNanos
      self.lastDelivery = ProcessInfo.processInfo.systemUptime
      guard self.decimator.admit(timestampNanos) else { return }
      self.samples.append(contentsOf: [timestampNanos, x, y, z])
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
    generation += 1
    lastTimestamp = nil
    decimator.reset()
    streamError = nil
    samples.removeAll(keepingCapacity: true)
    lock.unlock()
    sink = nil
  }

  /// Sends the samples taken since the previous flush. Runs on the main thread.
  private func flush() {
    lock.lock()
    // Availability alone does not guarantee Core Motion will deliver samples.
    // Use monotonic delivery time so a missing or stalled sensor cannot hang
    // calibration forever, including when an iOS app runs on a Mac.
    let now = ProcessInfo.processInfo.systemUptime
    // Suspension and a blocked main run loop delay both samples and this timer.
    // Give delivery a fresh grace period rather than treating that gap as failure.
    let appActive = UIApplication.shared.applicationState == .active
    if !appActive || now - lastFlush >= 2 {
      lastDelivery = now
    }
    lastFlush = now
    let failure = streamError ?? (listening && appActive && now - lastDelivery >= 2
      ? "Accelerometer stopped delivering valid samples" : nil)
    if let failure {
      lock.unlock()
      let events = sink
      stopUpdates()
      events?(FlutterError(code: "unavailable", message: failure, details: nil))
      return
    }
    let batch = samples
    samples.removeAll(keepingCapacity: true)
    let active = listening
    lock.unlock()
    guard active, !batch.isEmpty, let sink else { return }
    let bytes = batch.withUnsafeBufferPointer { Data(buffer: $0) }
    sink(FlutterStandardTypedData(float64: bytes))
  }
}

/// Keeps at most one sample per 20 ms slot of sensor time.
///
/// Slots are 20 ms wide and centred on `anchor + k × 20 ms`, where the anchor
/// is the first sample kept since `reset()`. A sample is kept only when its
/// slot is later than the last kept sample's. Judging against a fixed grid,
/// rather than the time since the last kept sample, is what lets a 50 Hz
/// source through whole: a minimum-spacing rule drops every sample that
/// arrives slightly early, so jitter alone would cost samples. On the grid a
/// 50 Hz source keeps everything while its jitter stays under 10 ms either
/// side of the anchor's phase, and a faster source keeps one sample per
/// slot, averaging 50 Hz with no drift.
///
/// No Core Motion or Flutter here, so it is tested on its own.
struct AccelerometerDecimator {
  /// 20 ms, the period of the seismometer's 50 Hz grid.
  static let periodNanos = 20_000_000.0

  private var anchor: Double?
  private var lastSlot = 0.0

  /// Whether to keep the sample taken at `timestampNanos`, in nanoseconds
  /// since boot. Expects increasing timestamps; the plugin drops any that are
  /// not before asking.
  mutating func admit(_ timestampNanos: Double) -> Bool {
    guard let anchor else {
      self.anchor = timestampNanos
      lastSlot = 0
      return true
    }
    let slot = ((timestampNanos - anchor) / Self.periodNanos + 0.5).rounded(.down)
    guard slot > lastSlot else { return false }
    lastSlot = slot
    return true
  }

  /// Forgets the anchor, so the next sample starts a new grid.
  mutating func reset() {
    anchor = nil
    lastSlot = 0
  }
}
