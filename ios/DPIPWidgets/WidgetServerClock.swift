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
        serverTimeSource: any WidgetServerTimeSource = WidgetSNTPClient(),
        timeoutRunner: any WidgetServerClockTimeoutRunning =
            WidgetTaskServerClockTimeout(),
        synchronizationTimeout: TimeInterval = 8
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
