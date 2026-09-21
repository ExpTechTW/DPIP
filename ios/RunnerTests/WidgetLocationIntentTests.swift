import Foundation
import XCTest
@testable import Runner

final class WidgetLocationIntentTests: XCTestCase {
    private func makeSnapshot(
        sourceIdentifier: String?,
        regionCode: String,
        schemaVersion: Int = 5
    ) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: schemaVersion,
            sourceIdentifier: sourceIdentifier,
            regionCode: regionCode,
            regionName: "測試地區",
            observationTime: 1_789_567_200,
            stationName: "測試站",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: false,
            nextDayNightTransitionTime: 1_789_562_700,
            calibratedTimeOffsetMilliseconds: 0,
            temperature: 28,
            humidity: 70,
            rain: 0
        )
    }

    func testMissingCatalogFallsBackToCurrentLocation() {
        let options = makeWidgetLocationOptions(
            from: nil,
            currentLocationDisplayString: "Current Location"
        )

        XCTAssertEqual(
            options,
            [
                WidgetLocationOption(
                    identifier: "current-location",
                    displayString: "Current Location"
                )
            ]
        )
    }

    func testCurrentLocationUsesLocalizedDisplayString() {
        let options = makeWidgetLocationOptions(
            from: nil,
            currentLocationDisplayString: "所在地"
        )

        XCTAssertEqual(options.first?.displayString, "所在地")
    }

    func testDefaultLocationOptionIsExplicitCurrentLocation() {
        let option = makeCurrentWidgetLocationOption(
            displayString: "所在地"
        )

        XCTAssertEqual(option.identifier, "current-location")
        XCTAssertEqual(option.displayString, "所在地")
    }

    func testCatalogLocationsPreserveSavedOrder() throws {
        let firstLocation = try XCTUnwrap(
            WidgetLocationCatalogLocation(
                regionCode: "220",
                displayName: "板橋區",
                administrativeAreaName: "新北市",
                latitude: 25.0096156,
                longitude: 121.4592358
            )
        )
        let secondLocation = try XCTUnwrap(
            WidgetLocationCatalogLocation(
                regionCode: "302",
                displayName: "竹北市",
                administrativeAreaName: "新竹縣",
                latitude: 24.8395807,
                longitude: 121.0040235
            )
        )
        let catalog = try XCTUnwrap(
            WidgetLocationCatalog(
                schemaVersion: 1,
                locations: [firstLocation, secondLocation]
            )
        )

        let options = makeWidgetLocationOptions(
            from: catalog,
            currentLocationDisplayString: "Current Location"
        )

        XCTAssertEqual(
            options,
            [
                WidgetLocationOption(
                    identifier: "current-location",
                    displayString: "Current Location"
                ),
                WidgetLocationOption(
                    identifier: "region:220",
                    displayString: "板橋區 — 新北市"
                ),
                WidgetLocationOption(
                    identifier: "region:302",
                    displayString: "竹北市 — 新竹縣"
                )
            ]
        )
    }

    func testMalformedCatalogStillYieldsCurrentLocationOnly() {
        let malformedCatalog = WidgetLocationCatalog.decode(
            Data(#"{"schemaVersion":1,"locations":[{}]}"#.utf8)
        )

        XCTAssertNil(malformedCatalog)
        XCTAssertEqual(
            makeWidgetLocationOptions(
                from: malformedCatalog,
                currentLocationDisplayString: "Current Location"
            ),
            [
                WidgetLocationOption(
                    identifier: "current-location",
                    displayString: "Current Location"
                )
            ]
        )
    }

    func testLocationTargetDefaultsToCurrentLocation() {
        XCTAssertEqual(
            WidgetLocationTarget(identifier: nil),
            .currentLocation
        )
    }

    func testLocationTargetParsesCurrentLocation() {
        XCTAssertEqual(
            WidgetLocationTarget(
                identifier: "current-location"
            ),
            .currentLocation
        )
    }

    func testLocationTargetParsesSavedRegion() {
        XCTAssertEqual(
            WidgetLocationTarget(
                identifier: "region:220"
            ),
            .saved(regionCode: "220")
        )
    }

    func testLocationTargetRejectsMalformedRegion() {
        for identifier in [
            "region:",
            "region:22",
            "region:2200",
            "region:abc",
            "region:２２０",
            "region:../../secret",
        ] {
            XCTAssertEqual(
                WidgetLocationTarget(identifier: identifier),
                .invalid(identifier: identifier)
            )
        }
    }

    func testLocationTargetRejectsUnknownIdentifier() {
        XCTAssertEqual(
            WidgetLocationTarget(
                identifier: "something-else"
            ),
            .invalid(identifier: "something-else")
        )
    }

    func testCurrentLocationMatchesCurrentLocationSnapshot() {
        let target = WidgetLocationTarget(
            identifier: "current-location"
        )

        let snapshot = makeSnapshot(
            sourceIdentifier: "current-location",
            regionCode: "220"
        )

        XCTAssertTrue(
            target.matches(snapshot: snapshot)
        )
    }

    func testSavedLocationMatchesSameSavedRegion() {
        let target = WidgetLocationTarget(
            identifier: "region:220"
        )

        let snapshot = makeSnapshot(
            sourceIdentifier: "region:220",
            regionCode: "220"
        )

        XCTAssertTrue(
            target.matches(snapshot: snapshot)
        )
    }

    func testSavedLocationRejectsDifferentSavedRegion() {
        let target = WidgetLocationTarget(
            identifier: "region:220"
        )

        let snapshot = makeSnapshot(
            sourceIdentifier: "region:302",
            regionCode: "302"
        )

        XCTAssertFalse(
            target.matches(snapshot: snapshot)
        )
    }

    func testSavedLocationRejectsMismatchedPayloadRegionCode() {
        let target = WidgetLocationTarget(
            identifier: "region:220"
        )

        let snapshot = makeSnapshot(
            sourceIdentifier: "region:220",
            regionCode: "302"
        )

        XCTAssertFalse(
            target.matches(snapshot: snapshot)
        )
    }

    func testCurrentLocationDoesNotMatchSavedSnapshot() {
        let target = WidgetLocationTarget(
            identifier: "current-location"
        )

        let snapshot = makeSnapshot(
            sourceIdentifier: "region:220",
            regionCode: "220"
        )

        XCTAssertFalse(
            target.matches(snapshot: snapshot)
        )
    }

    func testLegacySnapshotWithoutSourceDoesNotMatch() {
        let target = WidgetLocationTarget(
            identifier: "current-location"
        )

        let snapshot = makeSnapshot(
            sourceIdentifier: nil,
            regionCode: "220",
            schemaVersion: 4
        )

        XCTAssertFalse(
            target.matches(snapshot: snapshot)
        )
    }

    func testInvalidTargetNeverMatchesSnapshot() {
        let target = WidgetLocationTarget(
            identifier: "something-else"
        )

        let snapshot = makeSnapshot(
            sourceIdentifier: "current-location",
            regionCode: "220"
        )

        XCTAssertFalse(
            target.matches(snapshot: snapshot)
        )
    }
}
