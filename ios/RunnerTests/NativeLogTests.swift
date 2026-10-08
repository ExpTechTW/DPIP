import XCTest

final class NativeLogTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("native-log-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        directory = nil
        super.tearDown()
    }

    private var log: FileNativeLog {
        FileNativeLog(directory: directory)
    }

    func testAppendPreservesTimeAndTakeClears() throws {
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        log.record(
            level: .warning,
            tag: "widget",
            message: "refresh failed",
            time: when
        )
        log.record(
            level: .debug,
            tag: "widget",
            message: "cache after",
            time: when.addingTimeInterval(1)
        )

        let entries = try log.take()

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].level, "warning")
        XCTAssertEqual(entries[0].tag, "widget")
        XCTAssertEqual(entries[0].message, "refresh failed")
        XCTAssertEqual(entries[0].timeMillis, 1_700_000_000_000)
        XCTAssertEqual(entries[1].message, "cache after")
        XCTAssertEqual(entries[1].timeMillis, 1_700_000_001_000)
        let cleared = try log.take()
        XCTAssertTrue(cleared.isEmpty)
    }

    func testCapDropsTheOldestLines() throws {
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        for index in 0..<(FileNativeLog.maxEntries + 5) {
            log.record(
                level: .info,
                tag: "bg",
                message: "n\(index)",
                time: when.addingTimeInterval(TimeInterval(index))
            )
        }

        let entries = try log.take()

        XCTAssertEqual(entries.count, FileNativeLog.maxEntries)
        XCTAssertEqual(entries.first?.message, "n5")
        XCTAssertEqual(entries.last?.message, "n54")
        let cleared = try log.take()
        XCTAssertTrue(cleared.isEmpty)
    }

    func testEmptyMessageIsDropped() throws {
        log.record(
            level: .info,
            tag: "bg",
            message: "",
            time: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let cleared = try log.take()
        XCTAssertTrue(cleared.isEmpty)
    }

    func testConcurrentAppendsKeepEveryLine() throws {
        let log = self.log
        DispatchQueue.concurrentPerform(iterations: 40) { index in
            log.record(
                level: .info,
                tag: "bg",
                message: "line \(index)",
                time: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        let entries = try log.take()

        XCTAssertEqual(entries.count, 40)
        XCTAssertEqual(Set(entries.map(\.message)).count, 40)
        let cleared = try log.take()
        XCTAssertTrue(cleared.isEmpty)
    }
}
