import Foundation

/// Levels the Dart `Log` facade already knows by name.
enum NativeLogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
}

/// One line captured while the Flutter isolate was not running.
struct NativeLogEntry: Equatable, Sendable {
    var level: String
    var tag: String
    var message: String
    /// Unix epoch milliseconds, taken when the line was recorded.
    var timeMillis: Int64

    var wire: [String: Any] {
        [
            "level": level,
            "tag": tag,
            "message": message,
            "time": timeMillis,
        ]
    }
}

/// What native background, widget, and intent code logs through.
///
/// Callers depend on this, not on a file path. The production store is
/// [FileNativeLog].
protocol NativeLog: Sendable {
    func record(
        level: NativeLogLevel,
        tag: String,
        message: String,
        time: Date
    )
}

extension NativeLog {
    /// Captures the wall clock at the call, which is the event time.
    func record(level: NativeLogLevel, tag: String, message: String) {
        record(level: level, tag: tag, message: message, time: Date())
    }
}

/// File-backed ring in the widget app group, so an extension and the app
/// share one buffer across process death.
///
/// The ceiling is 50 lines, the same size as Android's background-location
/// breadcrumb ring: this only has to last until the next time the app opens
/// and drains it into `Log`, not for the 24-hour table. A message is clipped
/// at 2000 characters and a tag at 64, so one line cannot grow the file
/// without bound. Oldest lines are dropped.
struct FileNativeLog: NativeLog {
    static let maxEntries = 50
    static let maxMessageLength = 2000
    static let maxTagLength = 64
    static let filename = "native-log.json"
    static let appGroupIdentifier = "group.com.exptech.dpip.dpip.widgets"

    let fileURL: URL

    private static let gate = NSLock()

    init(directory: URL) {
        fileURL = directory.appendingPathComponent(Self.filename)
    }

    /// The shared buffer, or nil when the app group is not available.
    /// A nil result writes nothing; widget refresh must still complete.
    static func appGroup() -> FileNativeLog? {
        guard
            let directory = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            )
        else {
            return nil
        }
        return FileNativeLog(directory: directory)
    }

    func record(
        level: NativeLogLevel,
        tag: String,
        message: String,
        time: Date
    ) {
        let clipped = String(message.prefix(Self.maxMessageLength))
        guard !clipped.isEmpty else { return }
        let entry = NativeLogEntry(
            level: level.rawValue,
            tag: String(tag.prefix(Self.maxTagLength)),
            message: clipped,
            timeMillis: Self.millis(time)
        )
        do {
            try access { url in
                var entries = try Self.load(url)
                entries.append(entry)
                if entries.count > Self.maxEntries {
                    entries.removeFirst(entries.count - Self.maxEntries)
                }
                try Self.store(entries, at: url)
            }
        } catch {
            // A diagnostic must not take down the background work that logged it.
            return
        }
    }

    /// Reads the ring and replaces it with an empty one.
    ///
    /// The clear runs only after the read returns. An I/O failure throws
    /// with the previous file left in place, so a failed handoff can be
    /// retried. A corrupt file reads as empty and is then replaced.
    func take() throws -> [NativeLogEntry] {
        try access { url in
            let entries = try Self.load(url)
            try Self.store([], at: url)
            return entries
        }
    }

    private func access<T>(_ body: (URL) throws -> T) throws -> T {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var result: Result<T, Error>?
        // In-process writers share this lock. The coordinator covers a
        // widget extension and the app writing the same file at once.
        Self.gate.lock()
        defer { Self.gate.unlock() }
        try Self.prepare(fileURL)
        coordinator.coordinate(
            writingItemAt: fileURL,
            options: .forReplacing,
            error: &coordinationError
        ) { url in
            result = Result { try body(url) }
        }
        if let result {
            return try result.get()
        }
        if let coordinationError {
            throw coordinationError
        }
        throw CocoaError(.fileWriteUnknown)
    }

    private static func prepare(_ url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        if !FileManager.default.fileExists(atPath: url.path) {
            try Data("[]".utf8).write(to: url, options: .atomic)
        }
    }

    private static func load(_ url: URL) throws -> [NativeLogEntry] {
        if !FileManager.default.fileExists(atPath: url.path) {
            return []
        }
        let data = try Data(contentsOf: url)
        if data.isEmpty {
            return []
        }
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let rows = object as? [[String: Any]]
        else {
            return []
        }
        return rows.compactMap(entry(from:))
    }

    private static func entry(from row: [String: Any]) -> NativeLogEntry? {
        guard
            let level = row["level"] as? String,
            let tag = row["tag"] as? String,
            let message = row["message"] as? String,
            let time = (row["time"] as? NSNumber)?.int64Value
        else {
            return nil
        }
        return NativeLogEntry(
            level: level,
            tag: tag,
            message: message,
            timeMillis: time
        )
    }

    private static func store(
        _ entries: [NativeLogEntry],
        at url: URL
    ) throws {
        let rows: [[String: Any]] = entries.map { entry in
            [
                "level": entry.level,
                "tag": entry.tag,
                "message": entry.message,
                "time": NSNumber(value: entry.timeMillis),
            ]
        }
        let data = try JSONSerialization.data(withJSONObject: rows)
        try data.write(to: url, options: .atomic)
    }

    private static func millis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }
}
