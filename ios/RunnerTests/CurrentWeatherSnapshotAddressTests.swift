import XCTest
@testable import Runner

final class CurrentWeatherSnapshotAddressTests: XCTestCase {
    func testCurrentLocationAddress() {
        let address = CurrentWeatherSnapshotAddress(
            sourceIdentifier: "current-location"
        )

        XCTAssertEqual(address, .currentLocation)
        XCTAssertEqual(
            address?.sourceIdentifier,
            "current-location"
        )
        XCTAssertEqual(
            address?.filename,
            "current-location.json"
        )
    }

    func testSavedRegionAddress() {
        let address = CurrentWeatherSnapshotAddress(
            sourceIdentifier: "region:220"
        )

        XCTAssertEqual(
            address,
            .saved(regionCode: "220")
        )
        XCTAssertEqual(
            address?.sourceIdentifier,
            "region:220"
        )
        XCTAssertEqual(
            address?.filename,
            "region-220.json"
        )
    }

    func testRejectsInvalidSavedRegionIdentifiers() {
        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "region:"
            )
        )

        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "region:22"
            )
        )

        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "region:2200"
            )
        )

        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "region:abc"
            )
        )

        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "region:２２０"
            )
        )

        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "region:٢٢٠"
            )
        )

        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "region:../"
            )
        )
    }

    func testRejectsUnknownIdentifier() {
        XCTAssertNil(
            CurrentWeatherSnapshotAddress(
                sourceIdentifier: "unknown"
            )
        )
    }
}
