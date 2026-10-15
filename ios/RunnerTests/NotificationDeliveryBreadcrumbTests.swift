import XCTest

/// The delivery breadcrumb has to name the push without carrying its text, and
/// has to reach the ring the app drains at launch.
final class NotificationDeliveryBreadcrumbTests: XCTestCase {
    private struct Request: UNNotificationRequestLike {
        var identifier: String
        var userInfo: [AnyHashable: Any]
        var categoryIdentifier: String = ""
    }

    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("push-breadcrumb-\(UUID().uuidString)")
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

    func testReadsTheServerShapeAndLeavesTheTextOut() {
        // `content` as the JSON string the server sends, with the producer's
        // own map in `payload`.
        let content = """
            {"id": 7, "channelKey": "eew_alert-important-v2",
             "title": "地震速報", "body": "臺北市 震度 4",
             "payload": {"id": "eew-1145", "channel": "ignored"}}
            """
        let message = NotificationDeliveryBreadcrumb.message(
            userInfo: ["content": content, "aps": ["alert": "x"]],
            requestIdentifier: "6F0D2C1A-0000-4000-8000-000000000001",
            categoryIdentifier: ""
        )
        XCTAssertEqual(
            message,
            "delivered id=eew-1145 channel=eew_alert-important-v2 "
                + "apns=6F0D2C1A-0000-4000-8000-000000000001"
        )
        XCTAssertFalse(message.contains("地震"))
        XCTAssertFalse(message.contains("臺北"))
    }

    func testFallsBackToFlatKeysAndANumericId() {
        let message = NotificationDeliveryBreadcrumb.message(
            userInfo: ["id": NSNumber(value: 42), "channel": "report"],
            requestIdentifier: "",
            categoryIdentifier: "REPORT"
        )
        XCTAssertEqual(message, "delivered id=42 channel=report category=REPORT")
    }

    func testAPayloadWithNothingKnownStillSaysItArrived() {
        let message = NotificationDeliveryBreadcrumb.message(
            userInfo: ["content": "not json"],
            requestIdentifier: "",
            categoryIdentifier: ""
        )
        XCTAssertEqual(message, "delivered")
    }

    func testAFieldCannotPoseAsTwoOrGrowWithoutBound() {
        let message = NotificationDeliveryBreadcrumb.message(
            userInfo: ["channel": "eew channel=forged", "id": String(repeating: "9", count: 500)],
            requestIdentifier: "",
            categoryIdentifier: ""
        )
        XCTAssertTrue(message.contains("channel=eew_channel=forged"))
        let id = message.split(separator: " ").first { $0.hasPrefix("id=") }!
        XCTAssertEqual(id.count, "id=".count + NotificationDeliveryBreadcrumb.maxFieldLength)
    }

    func testRecordsIntoTheRingTheAppDrains() throws {
        let log = FileNativeLog(directory: directory)
        let when = Date(timeIntervalSince1970: 1_760_000_000)
        NotificationDeliveryBreadcrumb.record(
            Request(identifier: "apns-1", userInfo: ["id": "a1", "channel": "eq"]),
            time: when,
            log: log
        )

        let entries = try log.take()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].tag, "push")
        XCTAssertEqual(entries[0].level, "info")
        XCTAssertEqual(entries[0].message, "delivered id=a1 channel=eq apns=apns-1")
        XCTAssertEqual(entries[0].timeMillis, 1_760_000_000_000)
    }

    func testNoAppGroupWritesNothingAndDoesNotThrow() {
        NotificationDeliveryBreadcrumb.record(
            Request(identifier: "apns-1", userInfo: [:]),
            time: Date(),
            log: nil
        )
    }
}
