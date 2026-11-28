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

final class InMemoryClockAnchorStore: WidgetClockAnchorStoring,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var stored: WidgetClockAnchor?
    private var storedSaveCount = 0

    init(_ anchor: WidgetClockAnchor? = nil) {
        stored = anchor
    }

    var anchor: WidgetClockAnchor? { lock.withLock { stored } }
    var saveCount: Int { lock.withLock { storedSaveCount } }

    func load() -> WidgetClockAnchor? {
        lock.withLock { stored }
    }

    func save(_ anchor: WidgetClockAnchor) {
        lock.withLock {
            stored = anchor
            storedSaveCount += 1
        }
    }
}

final class TestBootMonotonicClock: WidgetMonotonicTimeSource,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var milliseconds: Int64
    private var boot: String?

    init(milliseconds: Int64, boot: String?) {
        self.milliseconds = milliseconds
        self.boot = boot
    }

    func elapsedMilliseconds() -> Int64 { lock.withLock { milliseconds } }
    func bootSessionIdentifier() -> String? { lock.withLock { boot } }

    func set(milliseconds: Int64, boot: String?) {
        lock.withLock {
            self.milliseconds = milliseconds
            self.boot = boot
        }
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
