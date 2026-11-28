import Foundation

protocol WidgetMonotonicTimeSource: Sendable {
    func elapsedMilliseconds() -> Int64

    /// Identifies the boot the readings belong to; `nil` when unknown.
    ///
    /// The monotonic clock restarts at zero on every boot, so an anchor kept
    /// across processes is only comparable within the boot that measured it.
    func bootSessionIdentifier() -> String?
}

extension WidgetMonotonicTimeSource {
    func bootSessionIdentifier() -> String? { nil }
}

struct WidgetSystemMonotonicTimeSource: WidgetMonotonicTimeSource {
    /// `CLOCK_MONOTONIC_RAW`, not `systemUptime`: uptime stops while the phone
    /// sleeps, and an anchor that outlives one widget process spans hours of
    /// sleep. This clock keeps counting through sleep and restarts at boot.
    func elapsedMilliseconds() -> Int64 {
        Int64(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) / 1_000_000)
    }

    func bootSessionIdentifier() -> String? {
        var size = 0
        guard sysctlbyname("kern.bootsessionuuid", nil, &size, nil, 0) == 0,
              size > 1
        else {
            return nil
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("kern.bootsessionuuid", &buffer, &size, nil, 0) == 0
        else {
            return nil
        }
        let identifier = buffer.withUnsafeBufferPointer {
            String(cString: $0.baseAddress!)
        }
        return identifier.isEmpty ? nil : identifier
    }
}

/// One successful server-time reading, kept so the next widget process can
/// keep calibrating after a failed synchronization.
///
/// The offset alone would not survive a device-clock change made after the
/// measurement, so the reading is anchored to the monotonic clock instead:
/// calibrated now = `serverUnixMilliseconds` + monotonic time elapsed since
/// `monotonicMilliseconds`. `offsetMilliseconds` records the server-minus-device
/// difference at the moment of measurement.
struct WidgetClockAnchor: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    let schemaVersion: Int
    let serverUnixMilliseconds: Int64
    let monotonicMilliseconds: Int64
    let offsetMilliseconds: Int64
    let bootSessionIdentifier: String?

    init(
        serverUnixMilliseconds: Int64,
        monotonicMilliseconds: Int64,
        offsetMilliseconds: Int64,
        bootSessionIdentifier: String?
    ) {
        schemaVersion = Self.schemaVersion
        self.serverUnixMilliseconds = serverUnixMilliseconds
        self.monotonicMilliseconds = monotonicMilliseconds
        self.offsetMilliseconds = offsetMilliseconds
        self.bootSessionIdentifier = bootSessionIdentifier
    }

    /// Usable only within the boot that measured it and for `maximumAge`.
    ///
    /// A reboot is caught twice: a different boot session, or a monotonic
    /// reading below the anchor's (the clock restarted). A boot whose session
    /// cannot be read at all fails closed, rather than trusting the second
    /// check alone, whenever the anchor did record one.
    func isUsable(
        monotonicNow: Int64,
        bootSessionIdentifier currentBoot: String?,
        maximumAge: TimeInterval
    ) -> Bool {
        guard schemaVersion == Self.schemaVersion,
              bootSessionIdentifier == currentBoot
                  || bootSessionIdentifier == nil
        else {
            return false
        }
        let elapsed = monotonicNow - monotonicMilliseconds
        return elapsed >= 0 && Double(elapsed) <= maximumAge * 1_000
    }
}

protocol WidgetClockAnchorStoring: Sendable {
    func load() -> WidgetClockAnchor?
    func save(_ anchor: WidgetClockAnchor)
}

/// `WidgetSnapshots/server-clock.json` in the App Group.
struct WidgetFileClockAnchorStore: WidgetClockAnchorStoring {
    let containerURL: URL

    private var url: URL {
        containerURL
            .appendingPathComponent("WidgetSnapshots", isDirectory: true)
            .appendingPathComponent("server-clock.json")
    }

    func load() -> WidgetClockAnchor? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetClockAnchor.self, from: data)
    }

    func save(_ anchor: WidgetClockAnchor) {
        guard let data = try? JSONEncoder().encode(anchor) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }
}

protocol WidgetServerClockTimeoutRunning: Sendable {
    func serverTimeUnixMilliseconds(
        from source: any WidgetServerTimeSource,
        timeout: TimeInterval
    ) async throws -> Int64
}

enum WidgetServerClockError: Error, Equatable {
    case timedOut
}

/// Tries each `WidgetServerTimeSource` in order and returns the first success.
///
/// Order is precision, not preference: `WidgetSNTPClient` first because its
/// RFC 5905 exchange resolves "now" to about a millisecond, then
/// `WidgetHTTPTimeSource` for the networks that block UDP/123, where one HTTPS
/// round trip gets within hundreds of milliseconds. A later source is consulted
/// only when every earlier one failed, so the accurate path is never traded away
/// for the reachable one.
///
/// Cancellation is not a failure to fall through from — `getTimeline` being torn
/// down should stop the chain, not send it on to the next host — so it
/// propagates instead of advancing, exactly as `WidgetSNTPClient` does across
/// its own hosts.
struct WidgetFallbackServerTimeSource: WidgetServerTimeSource {
    private let sources: [any WidgetServerTimeSource]

    init(_ sources: [any WidgetServerTimeSource]) {
        self.sources = sources
    }

    func serverTimeUnixMilliseconds() async throws -> Int64 {
        var lastError: Error = WidgetSNTPError.allHostsFailed
        for source in sources {
            do {
                return try await source.serverTimeUnixMilliseconds()
            } catch is CancellationError {
                throw CancellationError()
            } catch WidgetSNTPError.cancelled {
                throw CancellationError()
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}

struct WidgetTaskServerClockTimeout: WidgetServerClockTimeoutRunning {
    func serverTimeUnixMilliseconds(
        from source: any WidgetServerTimeSource,
        timeout: TimeInterval
    ) async throws -> Int64 {
        try await withThrowingTaskGroup(
            of: Int64.self,
            returning: Int64.self
        ) { group in
            group.addTask {
                try await source.serverTimeUnixMilliseconds()
            }
            group.addTask {
                let nanoseconds = UInt64(timeout * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
                throw WidgetServerClockError.timedOut
            }

            defer {
                group.cancelAll()
            }
            guard let result = try await group.next() else {
                throw WidgetServerClockError.timedOut
            }
            return result
        }
    }
}

actor WidgetServerClock {
    /// How long a persisted anchor may stand in for a fresh synchronization.
    static let maximumAnchorAge: TimeInterval = 24 * 60 * 60

    private let deviceClock: any WidgetWallTimeSource
    private let monotonicClock: any WidgetMonotonicTimeSource
    private let serverTimeSource: any WidgetServerTimeSource
    private let timeoutRunner: any WidgetServerClockTimeoutRunning
    private let synchronizationTimeout: TimeInterval
    private let anchorStore: (any WidgetClockAnchorStoring)?
    private let maximumAnchorAge: TimeInterval

    private var anchor: WidgetClockAnchor?
    private var synchronizationTask: Task<Bool, Never>?

    init(
        deviceClock: any WidgetWallTimeSource = WidgetSystemWallTimeSource(),
        monotonicClock: any WidgetMonotonicTimeSource =
            WidgetSystemMonotonicTimeSource(),
        // HTTP `/ntp` sits behind SNTP, not beside it: it is an order of
        // magnitude less precise, and is only reached on networks that block
        // UDP/123, where the alternative is no calibration at all.
        serverTimeSource: any WidgetServerTimeSource =
            WidgetFallbackServerTimeSource([
                WidgetSNTPClient(),
                WidgetHTTPTimeSource(),
            ]),
        timeoutRunner: any WidgetServerClockTimeoutRunning =
            WidgetTaskServerClockTimeout(),
        // Covers the whole chain, not one request: SNTP's primary→backup
        // fallback is 2 hosts × 3s, and the HTTP stage behind it adds 2s more.
        // Ten leaves headroom over that 8s worst case, and is only ever spent
        // when UDP/123 is blocked outright — the case the HTTP stage exists
        // for. A first-host success still returns in under 3s, which is what
        // getTimeline sees in the common path.
        synchronizationTimeout: TimeInterval = 10,
        // Widget processes are short-lived, so an anchor held only in memory
        // is usually gone by the next refresh. Persisting it lets a refresh
        // whose synchronization fails keep calibrating from the last reading.
        anchorStore: (any WidgetClockAnchorStoring)? = nil,
        maximumAnchorAge: TimeInterval = WidgetServerClock.maximumAnchorAge
    ) {
        self.deviceClock = deviceClock
        self.monotonicClock = monotonicClock
        self.serverTimeSource = serverTimeSource
        self.timeoutRunner = timeoutRunner
        self.synchronizationTimeout = synchronizationTimeout
        self.anchorStore = anchorStore
        self.maximumAnchorAge = maximumAnchorAge
    }

    /// Whether a usable anchor exists: this process's, or a persisted one
    /// that is still within its boot and age limits.
    var hasSynchronized: Bool {
        usableAnchor(monotonicNow: monotonicClock.elapsedMilliseconds()) != nil
    }

    @discardableResult
    func synchronize() async -> Bool {
        if let synchronizationTask {
            return await synchronizationTask.value
        }

        let task = Task { () -> Bool in
            do {
                let serverTime = try await timeoutRunner
                    .serverTimeUnixMilliseconds(
                        from: serverTimeSource,
                        timeout: synchronizationTimeout
                    )
                let anchor = WidgetClockAnchor(
                    serverUnixMilliseconds: serverTime,
                    monotonicMilliseconds:
                        monotonicClock.elapsedMilliseconds(),
                    offsetMilliseconds: serverTime - deviceUnixMilliseconds(),
                    bootSessionIdentifier:
                        monotonicClock.bootSessionIdentifier()
                )
                self.anchor = anchor
                anchorStore?.save(anchor)
                synchronizationTask = nil
                return true
            } catch {
                synchronizationTask = nil
                return false
            }
        }
        synchronizationTask = task
        return await task.value
    }

    func calibratedNowUnixMilliseconds() -> Int64 {
        let monotonicNow = monotonicClock.elapsedMilliseconds()
        guard let anchor = usableAnchor(monotonicNow: monotonicNow) else {
            return deviceUnixMilliseconds()
        }

        return anchor.serverUnixMilliseconds
            + monotonicNow
            - anchor.monotonicMilliseconds
    }

    /// Calibrated when an anchor is usable; otherwise the device clock with a
    /// zero correction. Never absent: an uncalibrated sample still carries a
    /// real observation, and discarding it is what left the widget stale.
    func currentWeatherSnapshotTime() -> CurrentWeatherSnapshotTime {
        let deviceNow = deviceUnixMilliseconds()
        // One monotonic reading decides both validity and the value, so the
        // sample is a single logical instant.
        let monotonicNow = monotonicClock.elapsedMilliseconds()
        guard let anchor = usableAnchor(monotonicNow: monotonicNow) else {
            return CurrentWeatherSnapshotTime(
                calibratedNowUnixMilliseconds: deviceNow,
                calibratedTimeOffsetMilliseconds: 0
            )
        }

        let calibratedNow = anchor.serverUnixMilliseconds
            + monotonicNow
            - anchor.monotonicMilliseconds
        return CurrentWeatherSnapshotTime(
            calibratedNowUnixMilliseconds: calibratedNow,
            calibratedTimeOffsetMilliseconds:
                Int(calibratedNow - deviceNow)
        )
    }

    private func usableAnchor(monotonicNow: Int64) -> WidgetClockAnchor? {
        let boot = monotonicClock.bootSessionIdentifier()
        if let anchor,
           anchor.isUsable(
               monotonicNow: monotonicNow,
               bootSessionIdentifier: boot,
               maximumAge: maximumAnchorAge
           ) {
            return anchor
        }
        guard let persisted = anchorStore?.load(),
              persisted.isUsable(
                  monotonicNow: monotonicNow,
                  bootSessionIdentifier: boot,
                  maximumAge: maximumAnchorAge
              )
        else {
            return nil
        }
        anchor = persisted
        return persisted
    }

    private func deviceUnixMilliseconds() -> Int64 {
        Int64(
            (deviceClock.now().timeIntervalSince1970 * 1_000).rounded()
        )
    }
}
