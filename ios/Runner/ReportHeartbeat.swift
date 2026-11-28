import BackgroundTasks
import CoreLocation
import Foundation

/// One report from a device that has gone quiet, in every location mode — the
/// iOS counterpart of Android's `ReportHeartbeat.kt`, with the same rule.
///
/// The backend counts a device as active from its `/v2/location` reports, and
/// some devices stop sending them while they still receive alerts: a township
/// pinned by hand stops background reporting altogether, and a phone that
/// never moves gives significant-change monitoring nothing to report. So a
/// `BGAppRefreshTask` asks whether the device's last successful report, from
/// any path (`LocationReportStore.reported`), is older than three days plus
/// this install's jitter, and if so sends exactly one.
///
/// It never asks Core Location for anything. The point is the pinned
/// township's reporting point while one is pinned (handed over by Dart), and
/// otherwise the point the last successful report sent. A device that has
/// never had a successful report has nothing to resend, and is skipped.
///
/// iOS, not this code, decides when an app refresh runs. `earliestBeginDate`
/// is only the earliest: the system weighs how often the user opens the app,
/// so an app that is seldom opened may be refreshed rarely or not at all, and
/// never while Background App Refresh is off for it. That is the limit of the
/// heartbeat here, and the reason it is scheduled for the moment it is due
/// rather than polled.
final class ReportHeartbeat {
  /// Listed in Info.plist's `BGTaskSchedulerPermittedIdentifiers`; registering
  /// an identifier that is not listed there raises.
  static let identifier = "com.exptech.dpip.report-heartbeat"

  static let shared = ReportHeartbeat(
    store: LocationReportSender.shared.store,
    send: { LocationReportSender.shared.sendHeartbeat($0, completion: $1) })

  let store: LocationReportStore
  private let send:
    (CLLocationCoordinate2D, @escaping (HeartbeatSendResult) -> Void) -> (() -> Void)?

  init(
    store: LocationReportStore,
    send: @escaping (CLLocationCoordinate2D, @escaping (HeartbeatSendResult) -> Void) -> (
      () -> Void
    )?
  ) {
    self.store = store
    self.send = send
  }

  // MARK: - Launch and scheduling

  /// Registers the task's handler and schedules the next run. Called once from
  /// `AppDelegate` at every launch — before launch finishes, as BGTaskScheduler
  /// requires, and before Flutter exists, which on a background launch for
  /// this very task it may never do.
  func launch() {
    let registered = BGTaskScheduler.shared.register(
      forTaskWithIdentifier: Self.identifier, using: .main
    ) { [weak self] task in
      guard let self, let task = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self.handle(task)
    }
    if !registered { note(.error, "heartbeat: the task could not be registered") }
    schedule(now: Date())
  }

  /// Asks for the next run at the moment the device comes due — see
  /// `ReportHeartbeatPolicy.earliestBegin`. A new request replaces the one
  /// already queued for this identifier.
  func schedule(now: Date) {
    let request = BGAppRefreshTaskRequest(identifier: Self.identifier)
    request.earliestBeginDate = ReportHeartbeatPolicy.earliestBegin(
      now: now, reported: store.reported, jitter: store.heartbeatJitter())
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      // The simulator has no scheduler, and a device with Background App
      // Refresh off refuses; either way there is nothing to retry until the
      // next launch.
      note(.warning, "heartbeat: not scheduled (\(error.localizedDescription))")
    }
  }

  /// One app-refresh wake: run, schedule the next, complete exactly once —
  /// whether the run finishes or the system takes the time back first.
  private func handle(_ task: BGAppRefreshTask) {
    var done = false
    var cancel: (() -> Void)?
    let complete: (Bool) -> Void = { [weak self] success in
      guard !done else { return }
      done = true
      self?.schedule(now: Date())
      task.setTaskCompleted(success: success)
    }
    // Called on a background queue when the system wants its time back. The
    // cancelled request still answers the run — as "no answer", which
    // records nothing — so this only cuts it short.
    task.expirationHandler = { [weak self] in
      DispatchQueue.main.async {
        guard !done else { return }
        self?.note(.warning, "heartbeat: the system ended the run before an answer")
        cancel?()
        complete(false)
      }
    }
    cancel = run(now: Date()) { _ in complete(true) }
  }

  // MARK: - One run

  /// Decides, sends at most once, and leaves a trace. A failure of any kind —
  /// a 429 included — only leaves the trace; the record stays as it was, so
  /// the next run is due again and retries. Returns a cancel for the request
  /// in flight, if one is.
  @discardableResult
  func run(now: Date, completion: @escaping (String) -> Void) -> (() -> Void)? {
    let decision = ReportHeartbeatPolicy.decide(
      now: now, reported: store.reported, jitter: store.heartbeatJitter(),
      manual: store.manualPoint)
    switch decision {
    case .skip(let reason):
      completion(finish(now, reason))
      return nil
    case .send(let point, let source):
      let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
      return send(coordinate) { [weak self] result in
        guard let self else { return }
        let outcome: String
        switch result {
        case .busy(let why): outcome = "\(why), not sent"
        case .noToken: outcome = "no push token, not sent"
        case .answered(let status):
          switch LocationReportPolicy.verdict(status: status) {
          case .delivered:
            self.store.recordReported(coordinate, at: now)
            outcome = "sent (\(status ?? 0))"
          case .rejected, .retry:
            outcome = "failed (\(status.map(String.init) ?? "no answer"))"
          }
        }
        completion(self.finish(now, "due, \(source): \(outcome)"))
      }
    }
  }

  @discardableResult
  private func finish(_ now: Date, _ outcome: String) -> String {
    store.recordHeartbeatRun(at: now, outcome: outcome)
    note(.info, "heartbeat: \(outcome)")
    return outcome
  }

  /// Into the native ring the app drains into its own log at the next launch.
  private func note(_ level: NativeLogLevel, _ message: String) {
    FileNativeLog.appGroup()?.record(level: level, tag: "BackgroundLocation", message: message)
  }

  // MARK: - Diagnostics

  /// The heartbeat's own evidence for the developer page, under the keys the
  /// Android channel uses. `heartbeatState` comes from the scheduler, which
  /// answers asynchronously — see `BackgroundLocationPlugin`.
  func diagnostics() -> [String: Any] {
    var out: [String: Any] = [:]
    let lastRun = store.defaults.double(forKey: LocationReportStore.heartbeatLastRunAtKey)
    if lastRun != 0 { out["heartbeatLastRunAt"] = Int(lastRun * 1000) }
    if let outcome = store.defaults.string(forKey: LocationReportStore.heartbeatLastOutcomeKey) {
      out["heartbeatLastOutcome"] = outcome
    }
    if let reported = store.reported {
      out["reportedAt"] = Int(reported.at.timeIntervalSince1970 * 1000)
      let due = ReportHeartbeatPolicy.dueAt(reported: reported, jitter: store.heartbeatJitter())
      out["heartbeatDueAt"] = Int(due.timeIntervalSince1970 * 1000)
    }
    return out
  }

  /// Whether the scheduler holds a request for the heartbeat, answered on
  /// the main queue — or "query unavailable" if it has not answered in time.
  static func state(_ answer: @escaping (String) -> Void) {
    var answered = false
    let reply: (String) -> Void = { state in
      guard !answered else { return }
      answered = true
      answer(state)
    }
    BGTaskScheduler.shared.getPendingTaskRequests { requests in
      let scheduled = requests.contains { $0.identifier == identifier }
      DispatchQueue.main.async { reply(scheduled ? "scheduled" : "missing") }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { reply("query unavailable") }
  }
}

/// The rule, apart from BGTaskScheduler and the network so it can be tested.
enum ReportHeartbeatPolicy {
  /// How long a device may go without a successful report.
  static let quiet: TimeInterval = 3 * 24 * 60 * 60
  /// The jitter is drawn from [0, this).
  static let jitterRange: TimeInterval = 24 * 60 * 60
  /// When the device is already due: try again in about an hour.
  static let retryDelay: TimeInterval = 60 * 60
  /// With nothing to resend yet: look again in about a day.
  static let noRecordDelay: TimeInterval = 24 * 60 * 60

  struct Point: Equatable {
    var latitude: Double
    var longitude: Double
  }

  enum Decision: Equatable {
    case skip(String)
    case send(Point, source: String)
  }

  static func dueAt(reported: ReportedFix, jitter: TimeInterval) -> Date {
    reported.at.addingTimeInterval(quiet + jitter)
  }

  /// Due once the last success is **more than** three days plus the jitter
  /// old. A last success stamped in the future is a clock that moved, not a
  /// recent report, and would otherwise hold the heartbeat off for as long as
  /// the clock was wrong; one report puts a sane stamp back.
  static func decide(
    now: Date, reported: ReportedFix?, jitter: TimeInterval, manual: CLLocationCoordinate2D?
  ) -> Decision {
    guard let reported else { return .skip("no successful report yet") }
    let age = now.timeIntervalSince(reported.at)
    if age >= 0, age <= quiet + jitter {
      return .skip("not due, last success \(Int(age / 3600)) h ago")
    }
    if let manual {
      return .send(
        Point(latitude: manual.latitude, longitude: manual.longitude), source: "pinned township")
    }
    return .send(
      Point(latitude: reported.latitude, longitude: reported.longitude),
      source: "last reported point")
  }

  /// When to ask iOS for the next run: the moment the device comes due; about
  /// an hour from now when that has passed (or the stamp is in the future);
  /// about a day from now when there is nothing to resend yet.
  static func earliestBegin(now: Date, reported: ReportedFix?, jitter: TimeInterval) -> Date {
    guard let reported else { return now.addingTimeInterval(noRecordDelay) }
    let due = dueAt(reported: reported, jitter: jitter)
    if reported.at > now || due <= now { return now.addingTimeInterval(retryDelay) }
    return due
  }
}
