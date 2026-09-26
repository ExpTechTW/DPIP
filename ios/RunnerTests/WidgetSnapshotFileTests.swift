import XCTest
@testable import Runner

final class WidgetSnapshotFileTests: XCTestCase {
    func testLocationCatalogDoesNotRequireSourceIdentifier() throws {
        let container = URL(
            fileURLWithPath: "/tmp/widget-test",
            isDirectory: true
        )

        let url = try WidgetSnapshotFile.snapshotURL(
            kind: .locationCatalog,
            sourceIdentifier: nil,
            in: container
        )

        XCTAssertEqual(
            url.path,
            "/tmp/widget-test/WidgetSnapshots/location-catalog.json"
        )
    }

    func testCurrentLocationSnapshotURL() throws {
        let container = URL(
            fileURLWithPath: "/tmp/widget-test",
            isDirectory: true
        )

        let url = try WidgetSnapshotFile.snapshotURL(
            kind: .currentWeather,
            sourceIdentifier: "current-location",
            in: container
        )

        XCTAssertEqual(
            url.path,
            "/tmp/widget-test/WidgetSnapshots/current-weather/current-location.json"
        )
    }

    func testSavedRegionSnapshotURL() throws {
        let container = URL(
            fileURLWithPath: "/tmp/widget-test",
            isDirectory: true
        )

        let url = try WidgetSnapshotFile.snapshotURL(
            kind: .currentWeather,
            sourceIdentifier: "region:220",
            in: container
        )

        XCTAssertEqual(
            url.path,
            "/tmp/widget-test/WidgetSnapshots/current-weather/region-220.json"
        )
    }

    func testCurrentWeatherRejectsMissingSourceIdentifier() {
        let container = URL(
            fileURLWithPath: "/tmp/widget-test",
            isDirectory: true
        )

        XCTAssertThrowsError(
            try WidgetSnapshotFile.snapshotURL(
                kind: .currentWeather,
                sourceIdentifier: nil,
                in: container
            )
        ) { error in
            XCTAssertEqual(
                error as? WidgetSnapshotError,
                .invalidPayload
            )
        }
    }

    func testCurrentWeatherRejectsInvalidSourceIdentifier() {
        let container = URL(
            fileURLWithPath: "/tmp/widget-test",
            isDirectory: true
        )

        XCTAssertThrowsError(
            try WidgetSnapshotFile.snapshotURL(
                kind: .currentWeather,
                sourceIdentifier: "region:../../secret",
                in: container
            )
        )
    }
}
