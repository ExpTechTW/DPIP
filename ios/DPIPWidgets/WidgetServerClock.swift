import Foundation

protocol WidgetMonotonicTimeSource: Sendable {
    func elapsedMilliseconds() -> Int64
}

struct WidgetSystemMonotonicTimeSource: WidgetMonotonicTimeSource {
    func elapsedMilliseconds() -> Int64 {
        Int64(ProcessInfo.processInfo.systemUptime * 1_000)
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
    private let deviceClock: any WidgetWallTimeSource
    private let monotonicClock: any WidgetMonotonicTimeSource
    private let serverTimeSource: any WidgetServerTimeSource
    private let timeoutRunner: any WidgetServerClockTimeoutRunning
    private let synchronizationTimeout: TimeInterval

    private var anchorServerUnixMilliseconds: Int64?
    private var anchorMonotonicMilliseconds: Int64?
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
        synchronizationTimeout: TimeInterval = 10
    ) {
        self.deviceClock = deviceClock
        self.monotonicClock = monotonicClock
        self.serverTimeSource = serverTimeSource
        self.timeoutRunner = timeoutRunner
        self.synchronizationTimeout = synchronizationTimeout
    }

    var hasSynchronized: Bool {
        anchorServerUnixMilliseconds != nil
            && anchorMonotonicMilliseconds != nil
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
                anchorServerUnixMilliseconds = serverTime
                anchorMonotonicMilliseconds =
                    monotonicClock.elapsedMilliseconds()
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
        guard let anchorServerUnixMilliseconds,
              let anchorMonotonicMilliseconds
        else {
            return deviceUnixMilliseconds()
        }

        return anchorServerUnixMilliseconds
            + monotonicClock.elapsedMilliseconds()
            - anchorMonotonicMilliseconds
    }

    func currentWeatherSnapshotTime() -> CurrentWeatherSnapshotTime {
        let deviceNow = deviceUnixMilliseconds()
        guard let anchorServerUnixMilliseconds,
              let anchorMonotonicMilliseconds
        else {
            return CurrentWeatherSnapshotTime(
                calibratedNowUnixMilliseconds: deviceNow,
                calibratedTimeOffsetMilliseconds: 0
            )
        }

        let calibratedNow = anchorServerUnixMilliseconds
            + monotonicClock.elapsedMilliseconds()
            - anchorMonotonicMilliseconds
        return CurrentWeatherSnapshotTime(
            calibratedNowUnixMilliseconds: calibratedNow,
            calibratedTimeOffsetMilliseconds:
                Int(calibratedNow - deviceNow)
        )
    }

    private func deviceUnixMilliseconds() -> Int64 {
        Int64(
            (deviceClock.now().timeIntervalSince1970 * 1_000).rounded()
        )
    }
}
