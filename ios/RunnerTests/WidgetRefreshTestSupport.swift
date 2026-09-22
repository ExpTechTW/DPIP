import Foundation

enum WidgetRefreshTestError: Error, Sendable {
    case scripted
}

final class TestWallClock: WidgetWallTimeSource, @unchecked Sendable {
    private let lock = NSLock()
    private var milliseconds: Int64
    private var storedReadCount = 0

    init(milliseconds: Int64) {
        self.milliseconds = milliseconds
    }

    var readCount: Int {
        lock.withLock { storedReadCount }
    }

    func now() -> Date {
        lock.withLock {
            storedReadCount += 1
            return Date(
                timeIntervalSince1970: TimeInterval(milliseconds) / 1_000
            )
        }
    }

    func set(milliseconds: Int64) {
        lock.withLock {
            self.milliseconds = milliseconds
        }
    }

    func resetReadCount() {
        lock.withLock {
            storedReadCount = 0
        }
    }
}

final class TestMonotonicClock: WidgetMonotonicTimeSource,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var milliseconds: Int64
    private var storedReadCount = 0

    init(milliseconds: Int64) {
        self.milliseconds = milliseconds
    }

    var readCount: Int {
        lock.withLock { storedReadCount }
    }

    func elapsedMilliseconds() -> Int64 {
        lock.withLock {
            storedReadCount += 1
            return milliseconds
        }
    }

    func set(milliseconds: Int64) {
        lock.withLock {
            self.milliseconds = milliseconds
        }
    }

    func resetReadCount() {
        lock.withLock {
            storedReadCount = 0
        }
    }
}

actor ScriptedServerTimeSource: WidgetServerTimeSource {
    private(set) var callCount = 0
    private var results: [Result<Int64, Error>]

    init(results: [Result<Int64, Error>]) {
        self.results = results
    }

    func serverTimeUnixMilliseconds() throws -> Int64 {
        callCount += 1
        guard !results.isEmpty else {
            throw WidgetSNTPError.allHostsFailed
        }
        return try results.removeFirst().get()
    }
}

struct PassthroughServerClockTimeoutRunner: WidgetServerClockTimeoutRunning {
    func serverTimeUnixMilliseconds(
        from source: any WidgetServerTimeSource,
        timeout: TimeInterval
    ) async throws -> Int64 {
        try await source.serverTimeUnixMilliseconds()
    }
}

actor AsyncOperationGate {
    private(set) var hasStarted = false
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        hasStarted = true
        guard !isOpen else {
            return
        }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

actor ScriptedCurrentWeather {
    struct Coordinates: Equatable, Sendable {
        let latitude: Double
        let longitude: Double
    }

    private(set) var callCount = 0
    private(set) var coordinates: [Coordinates] = []
    private let result: Result<CurrentWeatherRemoteDTO?, WidgetRefreshTestError>
    private let onFetch: @Sendable () -> Void

    init(
        result: Result<CurrentWeatherRemoteDTO?, WidgetRefreshTestError>,
        onFetch: @escaping @Sendable () -> Void = {}
    ) {
        self.result = result
        self.onFetch = onFetch
    }

    func fetch(
        latitude: Double,
        longitude: Double
    ) throws -> CurrentWeatherRemoteDTO? {
        onFetch()
        callCount += 1
        coordinates.append(
            Coordinates(latitude: latitude, longitude: longitude)
        )
        return try result.get()
    }
}

actor ScriptedSnapshotClock {
    private(set) var callCount = 0
    private let sample: CurrentWeatherSnapshotTime?

    init(sample: CurrentWeatherSnapshotTime?) {
        self.sample = sample
    }

    func synchronizeAndSample() -> CurrentWeatherSnapshotTime? {
        callCount += 1
        return sample
    }
}

final class CurrentWeatherSnapshotWriterSpy: @unchecked Sendable {
    private let lock = NSLock()
    private let error: WidgetRefreshTestError?
    private let onWrite: @Sendable () -> Void
    private var storedSnapshots: [CurrentWeatherWidgetSnapshot] = []
    private var storedWriteCount = 0

    init(
        error: WidgetRefreshTestError? = nil,
        onWrite: @escaping @Sendable () -> Void = {}
    ) {
        self.error = error
        self.onWrite = onWrite
    }

    var snapshots: [CurrentWeatherWidgetSnapshot] {
        lock.withLock { storedSnapshots }
    }

    var writeCount: Int {
        lock.withLock { storedWriteCount }
    }

    func write(_ snapshot: CurrentWeatherWidgetSnapshot) throws {
        onWrite()
        let error = lock.withLock {
            storedWriteCount += 1
            if self.error == nil {
                storedSnapshots.append(snapshot)
            }
            return self.error
        }
        if let error {
            throw error
        }
    }
}
