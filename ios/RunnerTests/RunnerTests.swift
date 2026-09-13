import Foundation
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  func testSnapshotKindAllowlist() throws {
    let kind = try WidgetSnapshotFile.kind("weatherForecast")
    XCTAssertEqual(kind.filename, "weather-forecast.json")
    XCTAssertEqual(kind.rawValue, "weatherForecast")
    XCTAssertThrowsError(try WidgetSnapshotFile.kind("../other.json")) { error in
      XCTAssertEqual(error as? WidgetSnapshotError, .invalidKind)
    }
  }

  func testPayloadValidationAndSizeLimit() throws {
    XCTAssertEqual(try WidgetSnapshotFile.payload("{\"schemaVersion\":1}"), Data("{\"schemaVersion\":1}".utf8))
    XCTAssertThrowsError(try WidgetSnapshotFile.payload("{")) { error in
      XCTAssertEqual(error as? WidgetSnapshotError, .invalidPayload)
    }
    XCTAssertThrowsError(try WidgetSnapshotFile.payload("[]")) { error in
      XCTAssertEqual(error as? WidgetSnapshotError, .invalidPayload)
    }
    let oversized = "{\"data\":\"\(String(repeating: "a", count: WidgetSnapshotFile.maximumPayloadBytes))\"}"
    XCTAssertThrowsError(try WidgetSnapshotFile.payload(oversized)) { error in
      XCTAssertEqual(error as? WidgetSnapshotError, .invalidPayload)
    }
  }

  func testAtomicSnapshotReplacement() throws {
    let container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: container) }
    let kind = try WidgetSnapshotFile.kind("weatherForecast")
    let first = try WidgetSnapshotFile.payload("{\"schemaVersion\":1,\"value\":\"old\"}")
    let second = try WidgetSnapshotFile.payload("{\"schemaVersion\":1,\"value\":\"new\"}")
    let target = container.appendingPathComponent("WidgetSnapshots/weather-forecast.json")

    try WidgetSnapshotFile.replace(first, kind: kind, in: container)
    XCTAssertEqual(try Data(contentsOf: target), first)
    try WidgetSnapshotFile.replace(second, kind: kind, in: container)
    XCTAssertEqual(try Data(contentsOf: target), second)
  }
}
