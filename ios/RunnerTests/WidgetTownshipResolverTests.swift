import Foundation
import XCTest

final class WidgetTownshipResolverTests: XCTestCase {
    func testAdjacentTownshipsAndAsymmetricCoordinatesResolveExactly() throws {
        let boundaries = try makeSyntheticBoundaries()

        XCTAssertEqual(
            boundaries.codeAt(latitude: 24.05, longitude: 120.05),
            "100"
        )
        XCTAssertEqual(
            boundaries.codeAt(latitude: 24.05, longitude: 120.15),
            "101"
        )
    }

    func testPolygonHoleDoesNotResolveAsContained() throws {
        let boundaries = try makeSyntheticBoundaries()

        XCTAssertEqual(
            boundaries.codeAt(latitude: 24.21, longitude: 120.01),
            "102"
        )
        XCTAssertNil(
            boundaries.codeAt(latitude: 24.25, longitude: 120.05)
        )
    }

    func testMultipartTownshipMatchesEitherPart() throws {
        let boundaries = try makeSyntheticBoundaries()

        XCTAssertEqual(
            boundaries.codeAt(latitude: 24.21, longitude: 120.21),
            "103"
        )
        XCTAssertEqual(
            boundaries.codeAt(latitude: 24.21, longitude: 120.26),
            "103"
        )
    }

    func testPointOutsideEveryTownshipReturnsNil() throws {
        let boundaries = try makeSyntheticBoundaries()

        XCTAssertNil(
            boundaries.codeAt(latitude: 24.5, longitude: 120.5)
        )
        XCTAssertNil(
            boundaries.codeAt(latitude: 24.15, longitude: 120.05)
        )
    }

    func testResolverFallsBackToNearestCentroid() throws {
        let resolver = try WidgetTownshipResolver(
            boundaries: makeSyntheticBoundaries(),
            directory: makeSyntheticDirectory()
        )
        let preciseLocation = try XCTUnwrap(
            WidgetCurrentLocation(latitude: 24.18, longitude: 120.05)
        )

        let resolved = try XCTUnwrap(resolver.resolve(preciseLocation))

        XCTAssertEqual(resolved.address, .currentLocation)
        XCTAssertEqual(resolved.regionCode, "102")
        XCTAssertEqual(resolved.regionName, "Hole區")
        XCTAssertEqual(resolved.latitude, 24.25)
        XCTAssertEqual(resolved.longitude, 120.05)
        XCTAssertNotEqual(resolved.latitude, preciseLocation.latitude)
    }

    func testIncompatibleBoundaryAndDirectoryCodesFailClosed() throws {
        let boundary = try WidgetTownshipBoundaryTable(
            shapes: [
                makeShape(
                    code: "100",
                    polygons: [
                        [[
                            (120.0, 24.0),
                            (120.1, 24.0),
                            (120.1, 24.1),
                            (120.0, 24.1),
                            (120.0, 24.0),
                        ]],
                    ]
                ),
            ]
        )

        XCTAssertThrowsError(
            try WidgetTownshipResolver(
                boundaries: boundary,
                directory: makeSyntheticDirectory()
            )
        ) { error in
            XCTAssertEqual(
                error as? WidgetTownshipResourceError,
                .incompatibleCodeSets
            )
        }
    }

    func testMalformedAndTruncatedBoundariesFailCleanly() {
        XCTAssertThrowsError(
            try WidgetTownshipBoundaryTable.decode(Data([0x80]))
        ) { error in
            XCTAssertEqual(
                error as? WidgetTownshipResourceError,
                .invalidBoundaryData
            )
        }
    }

    func testMalformedAndUnsupportedDirectoriesFailCleanly() {
        XCTAssertThrowsError(
            try WidgetTownshipDirectory.decode(Data("{}".utf8))
        ) { error in
            XCTAssertEqual(
                error as? WidgetTownshipResourceError,
                .invalidDirectory
            )
        }

        let unsupported = Data(
            #"{"schemaVersion":2,"townships":[]}"#.utf8
        )
        XCTAssertThrowsError(
            try WidgetTownshipDirectory.decode(unsupported)
        ) { error in
            XCTAssertEqual(
                error as? WidgetTownshipResourceError,
                .unsupportedDirectorySchema(2)
            )
        }
    }

    func testMissingBundleResourcesFailClosed() {
        let loader = WidgetTownshipResourceLoader(
            directoryName: "missing-directory",
            boundaryName: "missing-boundaries"
        )

        XCTAssertThrowsError(try loader.load(bundle: productionBundle)) {
            error in
            XCTAssertEqual(
                error as? WidgetTownshipResourceError,
                .missingResource("missing-directory.json")
            )
        }
    }

    func testProductionResourceCodeSetsAndDirectoryOrderMatch() throws {
        let resolver = try loadProductionResolver()

        XCTAssertEqual(resolver.directory.townships.count, 368)
        XCTAssertEqual(resolver.boundaries.regionCodes.count, 368)
        XCTAssertEqual(
            resolver.boundaries.regionCodes,
            resolver.directory.regionCodes
        )
        XCTAssertEqual(
            resolver.directory.townships.prefix(3).map(\.regionCode),
            ["100", "103", "104"]
        )
        XCTAssertEqual(
            resolver.directory.townships.suffix(3).map(\.regionCode),
            ["981", "982", "983"]
        )
        XCTAssertTrue(
            resolver.directory.regionCodes.allSatisfy { code in
                code.utf8.count == 3
                    && code.utf8.allSatisfy { $0 >= 48 && $0 <= 57 }
            }
        )
    }

    func testProductionGoldenCoordinatesResolveToTownshipCentroids() throws {
        let resolver = try loadProductionResolver()
        let goldens: [(
            latitude: Double,
            longitude: Double,
            code: String,
            name: String,
            centroidLatitude: Double,
            centroidLongitude: Double
        )] = [
            (25.0330, 121.5645, "110", "信義區", 25.0377271, 121.5818185),
            (24.1616, 120.6478, "407", "西屯區", 24.1658213, 120.6336717),
            (22.6210, 120.3120, "802", "苓雅區", 22.621759, 120.312194),
            (24.1000, 121.6000, "972", "秀林鄉", 24.1185835, 121.6248326),
        ]

        for golden in goldens {
            XCTAssertEqual(
                resolver.boundaries.codeAt(
                    latitude: golden.latitude,
                    longitude: golden.longitude
                ),
                golden.code
            )
            let input = try XCTUnwrap(
                WidgetCurrentLocation(
                    latitude: golden.latitude,
                    longitude: golden.longitude
                )
            )
            let resolved = try XCTUnwrap(resolver.resolve(input))
            XCTAssertEqual(resolved.address, .currentLocation)
            XCTAssertEqual(resolved.regionCode, golden.code)
            XCTAssertEqual(resolved.regionName, golden.name)
            XCTAssertEqual(resolved.latitude, golden.centroidLatitude)
            XCTAssertEqual(resolved.longitude, golden.centroidLongitude)
            XCTAssertTrue(
                resolved.latitude != input.latitude
                    || resolved.longitude != input.longitude
            )
        }
    }

    func testProductionSeaPointUsesDartNearestCentroidResult() throws {
        let resolver = try loadProductionResolver()
        let seaLocation = try XCTUnwrap(
            WidgetCurrentLocation(latitude: 24.0, longitude: 120.0)
        )

        XCTAssertNil(
            resolver.boundaries.codeAt(
                latitude: seaLocation.latitude,
                longitude: seaLocation.longitude
            )
        )
        let resolved = try XCTUnwrap(resolver.resolve(seaLocation))
        XCTAssertEqual(resolved.regionCode, "528")
        XCTAssertEqual(resolved.regionName, "芳苑鄉")
        XCTAssertEqual(resolved.latitude, 23.924354)
        XCTAssertEqual(resolved.longitude, 120.320389)
    }

    func testTruncatedProductionBoundaryCannotDowngradeToNearest() throws {
        let directoryData = try productionResourceData(
            name: "WidgetTownshipDirectory",
            extension: "json"
        )
        var boundaryData = try productionResourceData(
            name: "WidgetTownshipBoundaries",
            extension: "bin"
        )
        boundaryData.removeLast()

        XCTAssertThrowsError(
            try WidgetTownshipResourceLoader().load(
                directoryData: directoryData,
                boundaryData: boundaryData
            )
        ) { error in
            XCTAssertEqual(
                error as? WidgetTownshipResourceError,
                .invalidBoundaryData
            )
        }
    }

    private var productionBundle: Bundle {
        Bundle(for: Self.self)
    }

    private func loadProductionResolver() throws -> WidgetTownshipResolver {
        try WidgetTownshipResourceLoader().load(bundle: productionBundle)
    }

    private func productionResourceData(
        name: String,
        extension pathExtension: String
    ) throws -> Data {
        let url = try XCTUnwrap(
            productionBundle.url(
                forResource: name,
                withExtension: pathExtension
            )
        )
        return try Data(contentsOf: url)
    }

    private func makeSyntheticDirectory() throws -> WidgetTownshipDirectory {
        try WidgetTownshipDirectory(
            townships: [
                try makeTownship("100", "Alpha區", 24.05, 120.05),
                try makeTownship("101", "Beta區", 24.05, 120.15),
                try makeTownship("102", "Hole區", 24.25, 120.05),
                try makeTownship("103", "Multipart區", 24.21, 120.235),
            ]
        )
    }

    private func makeTownship(
        _ code: String,
        _ name: String,
        _ latitude: Double,
        _ longitude: Double
    ) throws -> WidgetTownship {
        try XCTUnwrap(
            WidgetTownship(
                regionCode: code,
                displayName: name,
                administrativeAreaName: "測試市",
                latitude: latitude,
                longitude: longitude
            )
        )
    }

    private func makeSyntheticBoundaries() throws
        -> WidgetTownshipBoundaryTable
    {
        try WidgetTownshipBoundaryTable(
            shapes: [
                makeShape(
                    code: "100",
                    polygons: [
                        [[
                            (120.0, 24.0),
                            (120.1, 24.0),
                            (120.1, 24.1),
                            (120.0, 24.1),
                            (120.0, 24.0),
                        ]],
                    ]
                ),
                makeShape(
                    code: "101",
                    polygons: [
                        [[
                            (120.1, 24.0),
                            (120.2, 24.0),
                            (120.2, 24.1),
                            (120.1, 24.1),
                            (120.1, 24.0),
                        ]],
                    ]
                ),
                makeShape(
                    code: "102",
                    polygons: [
                        [
                            [
                                (120.0, 24.2),
                                (120.1, 24.2),
                                (120.1, 24.3),
                                (120.0, 24.3),
                                (120.0, 24.2),
                            ],
                            [
                                (120.03, 24.23),
                                (120.07, 24.23),
                                (120.07, 24.27),
                                (120.03, 24.27),
                                (120.03, 24.23),
                            ],
                        ],
                    ]
                ),
                makeShape(
                    code: "103",
                    polygons: [
                        [[
                            (120.2, 24.2),
                            (120.22, 24.2),
                            (120.22, 24.22),
                            (120.2, 24.22),
                            (120.2, 24.2),
                        ]],
                        [[
                            (120.25, 24.2),
                            (120.27, 24.2),
                            (120.27, 24.22),
                            (120.25, 24.22),
                            (120.25, 24.2),
                        ]],
                    ]
                ),
            ]
        )
    }

    private func makeShape(
        code: String,
        polygons: [[[(Double, Double)]]]
    ) throws -> WidgetTownshipShape {
        try WidgetTownshipShape(
            regionCode: code,
            polygons: try polygons.map { rings in
                try WidgetTownshipPolygon(
                    rings: rings.map { ring in
                        ring.map { longitude, latitude in
                            WidgetTownshipCoordinate(
                                longitude: longitude,
                                latitude: latitude
                            )
                        }
                    }
                )
            }
        )
    }
}
