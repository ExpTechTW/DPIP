import Foundation
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  func testSnapshotKindAllowlist() throws {
    let kind = try WidgetSnapshotFile.kind("weatherForecast")
    XCTAssertEqual(kind.filename, "weather-forecast.json")
    XCTAssertEqual(kind.rawValue, "weatherForecast")

    let currentWeather = try WidgetSnapshotFile.kind("currentWeather")
    XCTAssertEqual(currentWeather.filename, "current-weather.json")
    XCTAssertEqual(currentWeather.rawValue, "currentWeather")

    let locationCatalog = try WidgetSnapshotFile.kind("locationCatalog")
    XCTAssertEqual(locationCatalog.filename, "location-catalog.json")
    XCTAssertEqual(locationCatalog.rawValue, "locationCatalog")
    XCTAssertNil(locationCatalog.widgetKind)

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

  func testCurrentWeatherRequestTokenPreservesArrivalOrder() throws {
    let container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: container) }
    let kind = try WidgetSnapshotFile.kind("currentWeather")
    let older = try WidgetSnapshotFile.beginCurrentWeatherWrite(
      sourceIdentifier: "current-location",
      in: container
    )
    let newer = try WidgetSnapshotFile.beginCurrentWeatherWrite(
      sourceIdentifier: "current-location",
      in: container
    )
    let olderData = try WidgetSnapshotFile.payload(
      "{\"schemaVersion\":5,\"observationTime\":100,\"regionCode\":\"407\"}"
    )
    let newerData = try WidgetSnapshotFile.payload(
      "{\"schemaVersion\":5,\"observationTime\":100,\"regionCode\":\"110\"}"
    )

    XCTAssertEqual(
      try WidgetSnapshotFile.replace(
        newerData,
        kind: kind,
        sourceIdentifier: "current-location",
        in: container,
        currentWeatherWriteToken: newer
      ),
      .written
    )
    XCTAssertEqual(
      try WidgetSnapshotFile.replace(
        olderData,
        kind: kind,
        sourceIdentifier: "current-location",
        in: container,
        currentWeatherWriteToken: older
      ),
      .rejected
    )

    let target = try WidgetSnapshotFile.snapshotURL(
      kind: kind,
      sourceIdentifier: "current-location",
      in: container
    )
    let stored = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: target))
        as? [String: Any]
    )
    XCTAssertEqual(stored["regionCode"] as? String, "110")
  }

  func testSnapshotClearIsIdempotent() throws {
    let container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: container) }
    let kind = try WidgetSnapshotFile.kind("currentWeather")
    let data = try WidgetSnapshotFile.payload(
      "{\"schemaVersion\":5,\"observationTime\":100,\"regionCode\":\"220\"}"
    )
    let directory = container.appendingPathComponent("WidgetSnapshots")
    let legacyTarget = directory.appendingPathComponent("current-weather.json")
    let perLocationTarget = try WidgetSnapshotFile.snapshotURL(
      kind: kind,
      sourceIdentifier: "region:220",
      in: container
    )

    XCTAssertNoThrow(try WidgetSnapshotFile.clear(kind, in: container))

    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    try data.write(to: legacyTarget, options: .atomic)
    try WidgetSnapshotFile.replace(
      data,
      kind: kind,
      sourceIdentifier: "region:220",
      in: container
    )
    XCTAssertTrue(FileManager.default.fileExists(atPath: legacyTarget.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: perLocationTarget.path))

    try WidgetSnapshotFile.clear(kind, in: container)
    XCTAssertFalse(FileManager.default.fileExists(atPath: legacyTarget.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: perLocationTarget.path))

    XCTAssertNoThrow(try WidgetSnapshotFile.clear(kind, in: container))
  }
}
