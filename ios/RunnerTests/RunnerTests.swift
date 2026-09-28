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

  func testSnapshotClearRemovesEveryCurrentWeatherSnapshot() throws {
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
    XCTAssertFalse(FileManager.default.fileExists(atPath: perLocationTarget.path))

    // The ordering sidecars went with them. Had one survived, it would claim a
    // committed snapshot that is no longer on disk, and every write from here
    // on would fail `invalidOrderingState` — a cleared widget that can never
    // be republished.
    XCTAssertNoThrow(
      try WidgetSnapshotFile.replace(
        data,
        kind: kind,
        sourceIdentifier: "region:220",
        in: container
      )
    )
    XCTAssertTrue(FileManager.default.fileExists(atPath: perLocationTarget.path))

    try WidgetSnapshotFile.clear(kind, in: container)
    XCTAssertNoThrow(try WidgetSnapshotFile.clear(kind, in: container))
  }

  func testSnapshotClearRemovesTheWidgetsForecastCache() throws {
    let container = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: container) }
    let kind = try WidgetSnapshotFile.kind("weatherForecast")
    let data = try WidgetSnapshotFile.payload("{\"schemaVersion\":1}")
    let directory = container.appendingPathComponent("WidgetSnapshots")
    let legacyTarget = directory.appendingPathComponent("weather-forecast.json")

    XCTAssertNoThrow(try WidgetSnapshotFile.clear(kind, in: container))

    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    try data.write(to: legacyTarget, options: .atomic)

    // Written by ForecastWidgetSnapshotStore, in the extension. The app never
    // puts a file here, which is why clearing used to walk past it: a forecast
    // survived "clear" and the widget went on drawing it.
    let cache = ForecastSnapshotLocation.directoryURL(in: container)
    let cached = cache.appendingPathComponent("region-220.json")
    try FileManager.default.createDirectory(
      at: cache,
      withIntermediateDirectories: true
    )
    try data.write(to: cached, options: .atomic)

    try WidgetSnapshotFile.clear(kind, in: container)
    XCTAssertFalse(FileManager.default.fileExists(atPath: legacyTarget.path))
    XCTAssertFalse(FileManager.default.fileExists(atPath: cached.path))
    XCTAssertFalse(FileManager.default.fileExists(atPath: cache.path))

    XCTAssertNoThrow(try WidgetSnapshotFile.clear(kind, in: container))
  }
}
