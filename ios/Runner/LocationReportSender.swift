import CoreLocation
import Foundation
import UIKit

/// Delivers background location reports, and keeps a fix until the server has
/// it.
///
/// A report used to be one GET with no retry, and the point it carried was
/// recorded as "reported" before the request had even left. One failure — a
/// train between stations, a basement car park — left the server on the old
/// township until the user next moved 150 m, and a user who stays put never
/// does. Now a fix is **pending** until a 2xx answers for it, and only a 2xx
/// moves the point the distance gate measures from.
///
/// A pending fix is retried on the next location wake, whenever the app
/// becomes active, and by the system itself through a **background
/// `URLSession`**:
///
///  - The request is handed to the system's transfer daemon, which sends it
///    once there is a network, whether or not this process is still alive.
///    The server-side effect — the device's location updated — needs nothing
///    from the app; only the bookkeeping does, and that arrives through
///    `handleEventsForBackgroundURLSession` or at the next launch.
///  - A failure the server asked to be retried (429, 408, 5xx) is queued with
///    `earliestBeginDate`, so the backoff holds even with the app gone.
///
/// Not a `BGProcessingTask`, which was the alternative. Those run only when
/// the device is idle — in practice overnight on a charger — and the system
/// terminates one the moment the user picks the phone up; they also need the
/// launch handler registered before launch finishes and Background App Refresh
/// switched on. "Some time tonight" is not a retry for a disaster alert's
/// target township. Nor does this need an Info.plist entry: a background
/// session takes no background mode and no permitted-identifier list.
///
/// What it cannot survive: a user force-quitting the app cancels the system's
/// transfers. The fix stays pending in `UserDefaults`, so the next launch or
/// wake sends it.
///
/// Everything here runs on the main queue — Core Location delivers there, and
/// the session's delegate queue is `.main` — so the state needs no lock.
final class LocationReportSender: NSObject, URLSessionDownloadDelegate {
  static let shared = LocationReportSender(store: LocationReportStore(defaults: .standard))

  /// The background session's identifier. `AppDelegate` routes this one's
  /// relaunch events here.
  static let sessionIdentifier = "com.exptech.dpip.location-report"

  let store: LocationReportStore

  /// The pending fix whose immediate attempt is on the wire, if any.
  private var inFlight: String?
  private var eventsCompletion: (() -> Void)?
  private var observers: [NSObjectProtocol] = []

  private lazy var backgroundSession: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
    config.sessionSendsLaunchEvents = true
    // Ignored for a task created while the app is in the background, which is
    // when most of these are created — the system then decides when to start
    // it. Set anyway for the ones queued from the foreground.
    config.isDiscretionary = false
    config.timeoutIntervalForResource = LocationReportPolicy.maxPendingAge
    store.defaults.set(true, forKey: LocationReportStore.sessionUsedKey)
    return URLSession(configuration: config, delegate: self, delegateQueue: .main)
  }()

  init(store: LocationReportStore) {
    self.store = store
    super.init()
  }

  /// Called once from `AppDelegate` at every launch, background relaunches
  /// included — before Flutter exists, which on a relaunch for a location
  /// event or a finished transfer it may never do.
  func launch() {
    let center = NotificationCenter.default
    let active: (Notification) -> Void = { [weak self] _ in self?.retryPending("active") }
    // Both: under the scene lifecycle UIKit no longer calls the app delegate's
    // `applicationDidBecomeActive`, and which notification still arrives is
    // not something to depend on. A second call is a no-op — the first one
    // is in flight.
    observers = [
      center.addObserver(
        forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main,
        using: active),
      center.addObserver(
        forName: UIScene.didActivateNotification, object: nil, queue: .main, using: active),
    ]
    // Results of transfers that finished while the process was gone are only
    // delivered once a session with the same identifier exists again.
    if store.pending != nil { _ = backgroundSession }
  }

  /// `AppDelegate.handleEventsForBackgroundURLSession` for this session.
  func handleEvents(_ completion: @escaping () -> Void) {
    eventsCompletion = completion
    _ = backgroundSession
  }

  /// Applies a new fix that the distance gate let through — see
  /// `LocationReportPolicy.action`.
  func process(_ coordinate: CLLocationCoordinate2D) {
    switch LocationReportPolicy.action(
      for: coordinate, lastDelivered: store.lastDelivered, pending: store.pending)
    {
    case .none:
      return
    case .discardPending:
      discardPending("back within range of the last delivered fix")
    case .retryPending:
      retryPending("wake")
    case .submit:
      let pending = store.replacePending(with: coordinate, now: Date())
      note(.info, "pending fix \(pending.id.prefix(8)) — reporting")
      attempt(pending)
    }
  }

  /// Sends the pending fix if it is due: on a wake, on becoming active, when a
  /// push token arrives. Before its backoff runs out it is left to the system
  /// transfer already queued for that moment.
  func retryPending(_ reason: String) {
    guard let pending = store.pending else { return }
    if LocationReportPolicy.isExpired(pending, now: Date()) {
      discardPending("expired after \(Int(LocationReportPolicy.maxPendingAge / 3600)) h")
      return
    }
    note(.debug, "retrying pending fix \(pending.id.prefix(8)) (\(reason))")
    attempt(pending)
  }

  /// Forgets the pending fix and the system transfer carrying it.
  func discardPending(_ reason: String) {
    guard let pending = store.pending else { return }
    store.clearPending()
    cancelQueued(except: nil)
    note(.info, "pending fix \(pending.id.prefix(8)) discarded: \(reason)")
  }

  // MARK: - Sending

  private func attempt(_ pending: PendingLocationReport) {
    // One request on the wire at a time. Its completion picks up whatever is
    // pending by then, so a newer fix is sent next rather than alongside it —
    // two at once is what draws the server's 429.
    guard inFlight == nil else { return }
    let now = Date()
    guard pending.notBefore <= now else {
      queueInBackground(pending)
      return
    }
    guard let url = store.url(for: pending) else {
      // No push token yet. Kept: `start` retries once Dart hands one over.
      note(.info, "pending fix \(pending.id.prefix(8)) kept: no push token")
      return
    }
    inFlight = pending.id
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
    request.timeoutInterval = 15

    // The wake window is short. If it closes first, the fix goes to the
    // system's transfer daemon instead, synchronously — after the expiration
    // handler returns this process may not run again.
    var backgroundTask = UIBackgroundTaskIdentifier.invalid
    let endBackgroundTask = {
      if backgroundTask != .invalid {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
      }
    }
    let dataTask = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
      let status = (response as? HTTPURLResponse)?.statusCode
      let cancelled = (error as? URLError)?.code == .cancelled
      DispatchQueue.main.async {
        defer { endBackgroundTask() }
        guard let self, self.inFlight == pending.id else { return }
        self.inFlight = nil
        // Cancelled only by the expiration handler, which queued it already.
        guard !cancelled else { return }
        self.finish(pending, status: status, error: error)
      }
    }
    backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "location report") {
      [weak self] in
      if let self {
        self.inFlight = nil
        self.queueInBackground(self.store.pending ?? pending)
      }
      dataTask.cancel()
      endBackgroundTask()
    }
    dataTask.resume()
  }

  /// Hands the fix to the system, to be sent once there is a network and not
  /// before its backoff. Replaces any transfer still queued for an older fix.
  private func queueInBackground(_ pending: PendingLocationReport) {
    guard let url = store.url(for: pending) else { return }
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
    request.timeoutInterval = 60
    // A download task because a background session accepts no data tasks; the
    // body is a few bytes nobody reads.
    let task = backgroundSession.downloadTask(with: request)
    task.taskDescription = pending.wire
    if pending.notBefore > Date() { task.earliestBeginDate = pending.notBefore }
    task.countOfBytesClientExpectsToSend = 512
    task.countOfBytesClientExpectsToReceive = 1024
    task.resume()
    cancelQueued(except: task.taskIdentifier)
    note(.debug, "pending fix \(pending.id.prefix(8)) queued with the system")
  }

  private func cancelQueued(except keep: Int?) {
    // Only when a session exists already: creating one to cancel nothing would
    // leave a background session behind on every device that never needed it.
    guard store.sessionUsed else { return }
    backgroundSession.getAllTasks { tasks in
      for task in tasks where task.taskIdentifier != keep { task.cancel() }
    }
  }

  /// Applies one answer to the fix it carried.
  ///
  /// The answer may be for a fix that has since been replaced — a system
  /// transfer finishing after a newer fix went out directly. It still says
  /// what the server now holds, so a 2xx still moves the delivered point;
  /// only the *current* pending fix is cleared or rescheduled.
  private func finish(_ sent: PendingLocationReport, status: Int?, error: Error?) {
    let now = Date()
    store.recordAttempt(at: now, status: status ?? -1)
    let current = store.pending?.id == sent.id
    let failure = error.map { " (\(type(of: $0)) \(($0 as NSError).code))" } ?? ""
    switch LocationReportPolicy.verdict(status: status) {
    case .delivered:
      store.markDelivered(sent.coordinate, at: now, status: status ?? 200)
      if current {
        store.clearPending()
        cancelQueued(except: nil)
      }
      note(.info, "fix \(sent.id.prefix(8)) delivered (HTTP \(status ?? 0))")
    case .rejected:
      if current { store.clearPending() }
      note(.warning, "fix \(sent.id.prefix(8)) rejected (HTTP \(status ?? 0)) — not retried")
    case .retry:
      guard current else { break }
      if LocationReportPolicy.isExpired(sent, now: now) {
        discardPending("expired after a failed attempt")
        return
      }
      let next = store.recordFailure(of: sent, now: now)
      note(
        .info,
        "fix \(sent.id.prefix(8)) not delivered (\(status.map { "HTTP \($0)" } ?? "no response")"
          + "\(failure)) — retry \(next.failures) after \(Int(next.notBefore.timeIntervalSince(now))) s"
      )
      queueInBackground(next)
    }
    // A fix that arrived while this one was on the wire.
    if let newer = store.pending, newer.id != sent.id { attempt(newer) }
  }

  // MARK: - URLSessionDownloadDelegate

  func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    // The response body is not used; the status is read on completion.
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    // Cancelled by this class when a fix was superseded or delivered, or by
    // the system when the user force-quit — the pending fix outlives both.
    if (error as? URLError)?.code == .cancelled { return }
    guard let sent = task.taskDescription.flatMap(PendingLocationReport.init(wire:)) else { return }
    finish(sent, status: (task.response as? HTTPURLResponse)?.statusCode, error: error)
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    let completion = eventsCompletion
    eventsCompletion = nil
    completion?()
  }

  // MARK: - Log

  /// Into the native ring the app drains into its own log at the next launch —
  /// a background wake has no Flutter isolate to log through.
  private func note(_ level: NativeLogLevel, _ message: String) {
    FileNativeLog.appGroup()?.record(level: level, tag: "BackgroundLocation", message: message)
  }
}

// MARK: - Decisions

/// What a report's answer means for the fix it carried.
enum LocationReportVerdict: Equatable {
  /// The server has the fix.
  case delivered
  /// Refused for a reason a retry would meet again.
  case rejected
  /// Nothing reached the server, or it asked to be asked again later.
  case retry
}

/// What a new fix should do to the pending one.
enum LocationReportAction: Equatable {
  case none
  case submit
  case retryPending
  case discardPending
}

/// The decisions, kept apart from URLSession and Core Location so they can be
/// tested.
enum LocationReportPolicy {
  /// Skip a fix within this distance of the last one, so significant-change,
  /// region and visit events for the same move don't each send a report.
  static let reportThresholdM: CLLocationDistance = 150
  static let firstBackoff: TimeInterval = 60
  static let maxBackoff: TimeInterval = 30 * 60
  /// A fix this old says where the device was, not where it is; past it the
  /// app's own daily re-registration is the better report.
  static let maxPendingAge: TimeInterval = 24 * 60 * 60

  /// `nil` is no HTTP response at all.
  ///
  /// A client error is final — the same request would be refused again — with
  /// two exceptions that mean "not now": 408 and 429. 429 is the one this
  /// endpoint actually sends, when two reports land inside its window.
  static func verdict(status: Int?) -> LocationReportVerdict {
    guard let status else { return .retry }
    switch status {
    case 200..<300: return .delivered
    case 408, 429: return .retry
    case 400..<500: return .rejected
    default: return .retry
    }
  }

  /// 1, 2, 4, … minutes after each consecutive failure, capped at 30.
  static func backoff(afterFailures failures: Int) -> TimeInterval {
    guard failures > 0 else { return 0 }
    return min(firstBackoff * pow(2, Double(min(failures - 1, 16))), maxBackoff)
  }

  static func isExpired(_ pending: PendingLocationReport, now: Date) -> Bool {
    now.timeIntervalSince(pending.since) > maxPendingAge
  }

  /// Distances are measured from what the server holds (the last *delivered*
  /// fix) and from what is already on its way (the pending one):
  ///
  ///  - back near the delivered fix: the server is already right, so a pending
  ///    fix is dropped rather than sent;
  ///  - near the pending fix: the same move reported again by another trigger,
  ///    so the pending fix is retried rather than replaced;
  ///  - anywhere else: a real move, which replaces the pending fix.
  static func action(
    for fix: CLLocationCoordinate2D, lastDelivered: CLLocationCoordinate2D?,
    pending: PendingLocationReport?
  ) -> LocationReportAction {
    if let lastDelivered, distance(fix, lastDelivered) < reportThresholdM {
      return pending == nil ? .none : .discardPending
    }
    if let pending, distance(fix, pending.coordinate) < reportThresholdM {
      return .retryPending
    }
    return .submit
  }

  static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D)
    -> CLLocationDistance
  {
    CLLocation(latitude: a.latitude, longitude: a.longitude)
      .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
  }
}

/// A fix not yet confirmed by the server.
struct PendingLocationReport: Equatable {
  var id: String
  var latitude: Double
  var longitude: Double
  /// When the fix was taken — what expiry is measured from.
  var since: Date
  /// Consecutive failed attempts.
  var failures: Int
  /// Not to be sent before this — the backoff.
  var notBefore: Date

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  /// Carried on a system transfer as its `taskDescription`, so an answer that
  /// arrives in another process still says which fix it was for.
  var wire: String {
    [
      id, "\(latitude)", "\(longitude)", "\(since.timeIntervalSince1970)", "\(failures)",
      "\(notBefore.timeIntervalSince1970)",
    ].joined(separator: " ")
  }

  init(
    id: String, latitude: Double, longitude: Double, since: Date, failures: Int, notBefore: Date
  ) {
    self.id = id
    self.latitude = latitude
    self.longitude = longitude
    self.since = since
    self.failures = failures
    self.notBefore = notBefore
  }

  init?(wire: String) {
    let parts = wire.split(separator: " ").map(String.init)
    guard parts.count == 6,
      let latitude = Double(parts[1]), let longitude = Double(parts[2]),
      let since = Double(parts[3]), let failures = Int(parts[4]),
      let notBefore = Double(parts[5])
    else { return nil }
    self.init(
      id: parts[0], latitude: latitude, longitude: longitude,
      since: Date(timeIntervalSince1970: since), failures: failures,
      notBefore: Date(timeIntervalSince1970: notBefore))
  }
}

/// The reporting state in `UserDefaults`, which survives the process — a
/// background wake starts with nothing else.
///
/// Key names before `pending` are the ones the plugin has always used, so an
/// upgrade keeps its configuration and its last delivered point.
struct LocationReportStore {
  static let enabledKey = "dpip.bgloc.enabled"
  static let tokenKey = "dpip.bgloc.token"
  static let versionKey = "dpip.bgloc.version"
  static let platformKey = "dpip.bgloc.platform"
  /// The last fix a 2xx answered for. It used to be written before the
  /// request was sent, which is the bug this type exists to fix.
  static let lastLatKey = "dpip.bgloc.lastLat"
  static let lastLngKey = "dpip.bgloc.lastLng"
  /// The latest attempt, whatever its outcome — diagnostics only.
  static let lastAttemptAtKey = "dpip.bgloc.lastReportAt"
  static let lastAttemptOkKey = "dpip.bgloc.lastReportOk"
  static let lastAttemptCodeKey = "dpip.bgloc.lastReportCode"
  static let lastSuccessAtKey = "dpip.bgloc.lastSuccessAt"
  static let lastSuccessCodeKey = "dpip.bgloc.lastSuccessCode"
  static let pendingKey = "dpip.bgloc.pending"
  static let sessionUsedKey = "dpip.bgloc.sessionUsed"

  let defaults: UserDefaults

  var lastDelivered: CLLocationCoordinate2D? {
    guard defaults.object(forKey: Self.lastLatKey) != nil else { return nil }
    return CLLocationCoordinate2D(
      latitude: defaults.double(forKey: Self.lastLatKey),
      longitude: defaults.double(forKey: Self.lastLngKey))
  }

  var lastSuccessAt: Date? {
    let at = defaults.double(forKey: Self.lastSuccessAtKey)
    return at == 0 ? nil : Date(timeIntervalSince1970: at)
  }

  var pending: PendingLocationReport? {
    defaults.string(forKey: Self.pendingKey).flatMap(PendingLocationReport.init(wire:))
  }

  /// Whether the background session was ever created on this install, so a
  /// cancel never has to create one just to find it empty.
  var sessionUsed: Bool { defaults.bool(forKey: Self.sessionUsedKey) }

  /// Makes [coordinate] the pending fix. A backoff already running carries
  /// over: a new fix is not a reason to ask a server that just said 429 again
  /// before it said to.
  @discardableResult
  func replacePending(with coordinate: CLLocationCoordinate2D, now: Date) -> PendingLocationReport
  {
    let previous = pending
    let backingOff = previous.map { $0.notBefore > now } ?? false
    let next = PendingLocationReport(
      id: UUID().uuidString, latitude: coordinate.latitude, longitude: coordinate.longitude,
      since: now, failures: backingOff ? previous!.failures : 0,
      notBefore: backingOff ? previous!.notBefore : now)
    defaults.set(next.wire, forKey: Self.pendingKey)
    return next
  }

  /// Counts a failed attempt and schedules the next one.
  @discardableResult
  func recordFailure(of pending: PendingLocationReport, now: Date) -> PendingLocationReport {
    var next = pending
    next.failures += 1
    next.notBefore = now.addingTimeInterval(LocationReportPolicy.backoff(afterFailures: next.failures))
    defaults.set(next.wire, forKey: Self.pendingKey)
    return next
  }

  func clearPending() {
    defaults.removeObject(forKey: Self.pendingKey)
  }

  func markDelivered(_ coordinate: CLLocationCoordinate2D, at: Date, status: Int) {
    defaults.set(coordinate.latitude, forKey: Self.lastLatKey)
    defaults.set(coordinate.longitude, forKey: Self.lastLngKey)
    defaults.set(at.timeIntervalSince1970, forKey: Self.lastSuccessAtKey)
    defaults.set(status, forKey: Self.lastSuccessCodeKey)
  }

  func recordAttempt(at: Date, status: Int) {
    defaults.set(at.timeIntervalSince1970, forKey: Self.lastAttemptAtKey)
    defaults.set((200..<300).contains(status), forKey: Self.lastAttemptOkKey)
    defaults.set(status, forKey: Self.lastAttemptCodeKey)
  }

  /// The report URL with the configuration as it is *now* — a fix that waited
  /// out a token change goes out under the new token.
  func url(for pending: PendingLocationReport) -> URL? {
    guard
      let token = defaults.string(forKey: Self.tokenKey),
      let version = defaults.string(forKey: Self.versionKey)
    else { return nil }
    let platform = defaults.integer(forKey: Self.platformKey)
    // coreExclusiveApi is tnn1-only (no failover) — matches ApiTier.coreExclusiveApi.
    return URL(
      string:
        "https://api.core-tnn1.exptech.dev/api/v2/location/\(platform)/\(token)/\(version)/\(pending.latitude),\(pending.longitude)"
    )
  }
}
