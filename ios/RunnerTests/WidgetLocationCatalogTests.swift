import XCTest
@testable import Runner

final class WidgetLocationCatalogTests: XCTestCase {
    func testDecodesSchemaVersionOneCatalog() throws {
        let catalog = try XCTUnwrap(
            WidgetLocationCatalog.decode(
                validCatalogData()
            )
        )

        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertEqual(catalog.locations.count, 1)
        XCTAssertEqual(catalog.locations[0].regionCode, "242")
        XCTAssertEqual(catalog.locations[0].displayName, "新莊區")
        XCTAssertEqual(
            catalog.locations[0].administrativeAreaName,
            "新北市"
        )
        XCTAssertEqual(catalog.locations[0].latitude, 25.0358303)
        XCTAssertEqual(catalog.locations[0].longitude, 121.4500307)
    }

    func testEmptyCatalogIsValid() throws {
        let catalog = try XCTUnwrap(
            WidgetLocationCatalog.decode(
                Data(
                    #"{"schemaVersion":1,"locations":[]}"#.utf8
                )
            )
        )

        XCTAssertEqual(catalog.locations, [])
    }

    func testAcceptsCoordinateBoundaries() throws {
        let coordinates = [
            (-90.0, -180.0),
            (-90.0, 180.0),
            (90.0, -180.0),
            (90.0, 180.0),
        ]

        for (latitude, longitude) in coordinates {
            let catalog = try XCTUnwrap(
                WidgetLocationCatalog.decode(
                    validCatalogData(
                        latitude: latitude,
                        longitude: longitude
                    )
                )
            )

            XCTAssertEqual(catalog.locations[0].latitude, latitude)
            XCTAssertEqual(catalog.locations[0].longitude, longitude)
        }
    }

    func testRejectsUnsupportedSchemaVersion() {
        XCTAssertNil(
            WidgetLocationCatalog.decode(
                validCatalogData(schemaVersion: 2)
            )
        )
    }

    func testRejectsMalformedTopLevelJSON() {
        XCTAssertNil(
            WidgetLocationCatalog.decode(
                Data(#"{"schemaVersion":1,"locations":["#.utf8)
            )
        )
        XCTAssertNil(
            WidgetLocationCatalog.decode(
                Data(#"[]"#.utf8)
            )
        )
    }

    func testRejectsMalformedEntryWithoutPartialCatalog() {
        let json = """
        {
          "schemaVersion": 1,
          "locations": [
            {
              "regionCode": "242",
              "displayName": "新莊區",
              "administrativeAreaName": "新北市",
              "latitude": 25.0358303,
              "longitude": 121.4500307
            },
            {
              "regionCode": "433"
            }
          ]
        }
        """

        XCTAssertNil(
            WidgetLocationCatalog.decode(Data(json.utf8))
        )
    }

    func testRejectsInvalidRegionCode() {
        for regionCode in ["", "24", "2420", "abc"] {
            XCTAssertNil(
                WidgetLocationCatalog.decode(
                    validCatalogData(regionCode: regionCode)
                ),
                regionCode
            )
        }
    }

    func testRejectsUnicodeNumericRegionCode() {
        for regionCode in ["２４２", "٢٤٢"] {
            XCTAssertNil(
                WidgetLocationCatalog.decode(
                    validCatalogData(regionCode: regionCode)
                ),
                regionCode
            )
        }
    }

    func testRejectsNonFiniteLatitudeThroughDirectValidation() {
        for latitude in [Double.nan, .infinity, -.infinity] {
            XCTAssertNil(
                WidgetLocationCatalogLocation(
                    regionCode: "242",
                    displayName: "新莊區",
                    administrativeAreaName: "新北市",
                    latitude: latitude,
                    longitude: 121.4500307
                )
            )
        }
    }

    func testRejectsNonFiniteLongitudeThroughDirectValidation() {
        for longitude in [Double.nan, .infinity, -.infinity] {
            XCTAssertNil(
                WidgetLocationCatalogLocation(
                    regionCode: "242",
                    displayName: "新莊區",
                    administrativeAreaName: "新北市",
                    latitude: 25.0358303,
                    longitude: longitude
                )
            )
        }
    }

    func testRejectsOutOfBoundsLatitude() {
        for latitude in [-90.000_001, 90.000_001] {
            XCTAssertNil(
                WidgetLocationCatalog.decode(
                    validCatalogData(latitude: latitude)
                ),
                "latitude \(latitude)"
            )
        }
    }

    func testRejectsOutOfBoundsLongitude() {
        for longitude in [-180.000_001, 180.000_001] {
            XCTAssertNil(
                WidgetLocationCatalog.decode(
                    validCatalogData(longitude: longitude)
                ),
                "longitude \(longitude)"
            )
        }
    }

    func testRejectsDuplicateRegionCodes() {
        let json = """
        {
          "schemaVersion": 1,
          "locations": [
            {
              "regionCode": "242",
              "displayName": "新莊區",
              "administrativeAreaName": "新北市",
              "latitude": 25.0358303,
              "longitude": 121.4500307
            },
            {
              "regionCode": "242",
              "displayName": "另一個地區",
              "administrativeAreaName": "新北市",
              "latitude": 25.1,
              "longitude": 121.5
            }
          ]
        }
        """

        XCTAssertNil(
            WidgetLocationCatalog.decode(Data(json.utf8))
        )
    }

    private func validCatalogData(
        schemaVersion: Int = 1,
        regionCode: String = "242",
        displayName: String = "新莊區",
        latitude: Double = 25.0358303,
        longitude: Double = 121.4500307
    ) -> Data {
        Data(
            """
            {
              "schemaVersion": \(schemaVersion),
              "locations": [
                {
                  "regionCode": "\(regionCode)",
                  "displayName": "\(displayName)",
                  "administrativeAreaName": "新北市",
                  "latitude": \(latitude),
                  "longitude": \(longitude)
                }
              ]
            }
            """.utf8
        )
    }
}

final class SavedWidgetLocationResolverTests: XCTestCase {
    func testRegion242ResolvesExactEntry() throws {
        let resolver = try makeResolver(codes: ["242", "433"])

        XCTAssertEqual(
            resolver.resolve(
                target: WidgetLocationTarget(identifier: "region:242")
            ),
            WidgetResolvedWeatherLocation(
                address: .saved(regionCode: "242"),
                regionCode: "242",
                regionName: "新莊區",
                latitude: 25.0358303,
                longitude: 121.4500307
            )
        )
    }

    func testRegion433ResolvesIndependently() throws {
        let resolver = try makeResolver(codes: ["242", "433"])

        XCTAssertEqual(
            resolver.resolve(
                target: WidgetLocationTarget(identifier: "region:433")
            )?.regionCode,
            "433"
        )
    }

    func testMissingRegionReturnsUnresolved() throws {
        let resolver = try makeResolver(codes: ["242"])

        XCTAssertNil(
            resolver.resolve(
                target: WidgetLocationTarget(identifier: "region:433")
            )
        )
    }

    func testRemovedRegionReturnsUnresolved() throws {
        let resolverBeforeRemoval = try makeResolver(codes: ["242", "433"])
        let resolverAfterRemoval = try makeResolver(codes: ["433"])
        let target = WidgetLocationTarget(identifier: "region:242")

        XCTAssertNotNil(resolverBeforeRemoval.resolve(target: target))
        XCTAssertNil(resolverAfterRemoval.resolve(target: target))
    }

    func testMissingCatalogReturnsUnresolved() {
        let resolver = SavedWidgetLocationResolver(catalog: nil)

        XCTAssertNil(
            resolver.resolve(
                target: WidgetLocationTarget(identifier: "region:242")
            )
        )
    }

    func testCurrentLocationIsNotResolved() throws {
        let resolver = try makeResolver(codes: ["242"])

        XCTAssertNil(
            resolver.resolve(target: .currentLocation)
        )
    }

    func testInvalidTargetIsNotResolved() throws {
        let resolver = try makeResolver(codes: ["242"])

        XCTAssertNil(
            resolver.resolve(
                target: WidgetLocationTarget(identifier: "region:２４２")
            )
        )
    }

    func testEntryOrderDoesNotChangeExactMatching() throws {
        let target = WidgetLocationTarget(identifier: "region:242")
        let forward = try makeResolver(codes: ["242", "433"])
        let reversed = try makeResolver(codes: ["433", "242"])

        XCTAssertEqual(
            forward.resolve(target: target),
            reversed.resolve(target: target)
        )
    }

    private func makeResolver(
        codes: [String]
    ) throws -> SavedWidgetLocationResolver {
        let locations = try codes.map(makeLocation)
        let catalog = try XCTUnwrap(
            WidgetLocationCatalog(
                schemaVersion: 1,
                locations: locations
            )
        )

        return SavedWidgetLocationResolver(catalog: catalog)
    }

    private func makeLocation(
        regionCode: String
    ) throws -> WidgetLocationCatalogLocation {
        switch regionCode {
        case "242":
            return try XCTUnwrap(
                WidgetLocationCatalogLocation(
                    regionCode: "242",
                    displayName: "新莊區",
                    administrativeAreaName: "新北市",
                    latitude: 25.0358303,
                    longitude: 121.4500307
                )
            )

        case "433":
            return try XCTUnwrap(
                WidgetLocationCatalogLocation(
                    regionCode: "433",
                    displayName: "沙鹿區",
                    administrativeAreaName: "臺中市",
                    latitude: 24.2338622,
                    longitude: 120.565703
                )
            )

        default:
            throw NSError(domain: "SavedWidgetLocationResolverTests", code: 1)
        }
    }
}
