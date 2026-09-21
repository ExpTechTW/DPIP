import Foundation

enum WidgetTownshipResourceError: Error, Equatable {
    case missingResource(String)
    case unsupportedDirectorySchema(Int)
    case invalidDirectory
    case invalidBoundaryData
    case incompatibleCodeSets
}

struct WidgetTownship: Equatable, Sendable {
    let regionCode: String
    let displayName: String
    let administrativeAreaName: String
    let latitude: Double
    let longitude: Double

    init?(
        regionCode: String,
        displayName: String,
        administrativeAreaName: String,
        latitude: Double,
        longitude: Double
    ) {
        guard
            WidgetResolvedWeatherLocationValidation
                .isValidRegionCode(regionCode),
            !displayName.isEmpty,
            !administrativeAreaName.isEmpty,
            latitude.isFinite,
            longitude.isFinite,
            (-90 ... 90).contains(latitude),
            (-180 ... 180).contains(longitude)
        else {
            return nil
        }

        self.regionCode = regionCode
        self.displayName = displayName
        self.administrativeAreaName = administrativeAreaName
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct WidgetTownshipDirectory: Sendable {
    static let supportedSchemaVersion = 1

    let townships: [WidgetTownship]
    private let byCode: [String: WidgetTownship]

    init(townships: [WidgetTownship]) throws {
        guard !townships.isEmpty else {
            throw WidgetTownshipResourceError.invalidDirectory
        }

        let byCode = Dictionary(
            townships.map { ($0.regionCode, $0) },
            uniquingKeysWith: { first, _ in
                // The count check below rejects the full directory.
                // Keeping the first value here avoids an initializer trap.
                first
            }
        )
        guard byCode.count == townships.count else {
            throw WidgetTownshipResourceError.invalidDirectory
        }

        self.townships = townships
        self.byCode = byCode
    }

    static func decode(_ data: Data) throws -> Self {
        let raw: RawDirectory
        do {
            raw = try JSONDecoder().decode(RawDirectory.self, from: data)
        } catch {
            throw WidgetTownshipResourceError.invalidDirectory
        }

        guard raw.schemaVersion == supportedSchemaVersion else {
            throw WidgetTownshipResourceError.unsupportedDirectorySchema(
                raw.schemaVersion
            )
        }

        let townships = try raw.townships.map { rawTownship in
            guard let township = WidgetTownship(
                regionCode: rawTownship.regionCode,
                displayName: rawTownship.displayName,
                administrativeAreaName: rawTownship.administrativeAreaName,
                latitude: rawTownship.latitude,
                longitude: rawTownship.longitude
            ) else {
                throw WidgetTownshipResourceError.invalidDirectory
            }
            return township
        }
        return try Self(townships: townships)
    }

    var regionCodes: Set<String> {
        Set(byCode.keys)
    }

    func township(regionCode: String) -> WidgetTownship? {
        byCode[regionCode]
    }

    /// Matches Dart TownDirectory.nearest: one cosine for the query latitude,
    /// source-directory order for ties, and strict `<` replacement.
    func nearest(latitude: Double, longitude: Double) -> WidgetTownship? {
        let cosine = cos(latitude * .pi / 180)
        var best: WidgetTownship?
        var bestSquaredDistance = Double.infinity

        for township in townships {
            let latitudeDelta = latitude - township.latitude
            let longitudeDelta = (longitude - township.longitude) * cosine
            let squaredDistance = latitudeDelta * latitudeDelta
                + longitudeDelta * longitudeDelta
            if squaredDistance < bestSquaredDistance {
                bestSquaredDistance = squaredDistance
                best = township
            }
        }
        return best
    }
}

private struct RawDirectory: Decodable {
    let schemaVersion: Int
    let townships: [RawTownship]
}

private struct RawTownship: Decodable {
    let regionCode: String
    let displayName: String
    let administrativeAreaName: String
    let latitude: Double
    let longitude: Double
}

struct WidgetTownshipCoordinate: Equatable, Sendable {
    let longitude: Double
    let latitude: Double
}

struct WidgetTownshipPolygon: Sendable {
    /// First ring is the outer ring; subsequent rings are holes.
    let rings: [[WidgetTownshipCoordinate]]

    init(rings: [[WidgetTownshipCoordinate]]) throws {
        guard !rings.isEmpty, rings.allSatisfy({ $0.count >= 3 }) else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }
        self.rings = rings
    }
}

struct WidgetTownshipShape: Sendable {
    let regionCode: String
    let polygons: [WidgetTownshipPolygon]
    let minLongitude: Double
    let minLatitude: Double
    let maxLongitude: Double
    let maxLatitude: Double

    init(
        regionCode: String,
        polygons: [WidgetTownshipPolygon]
    ) throws {
        guard
            WidgetResolvedWeatherLocationValidation
                .isValidRegionCode(regionCode),
            !polygons.isEmpty
        else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }

        var minLongitude = Double.infinity
        var minLatitude = Double.infinity
        var maxLongitude = -Double.infinity
        var maxLatitude = -Double.infinity
        for polygon in polygons {
            for ring in polygon.rings {
                for point in ring {
                    guard
                        point.longitude.isFinite,
                        point.latitude.isFinite,
                        (-180 ... 180).contains(point.longitude),
                        (-90 ... 90).contains(point.latitude)
                    else {
                        throw WidgetTownshipResourceError.invalidBoundaryData
                    }
                    minLongitude = min(minLongitude, point.longitude)
                    minLatitude = min(minLatitude, point.latitude)
                    maxLongitude = max(maxLongitude, point.longitude)
                    maxLatitude = max(maxLatitude, point.latitude)
                }
            }
        }

        self.regionCode = regionCode
        self.polygons = polygons
        self.minLongitude = minLongitude
        self.minLatitude = minLatitude
        self.maxLongitude = maxLongitude
        self.maxLatitude = maxLatitude
    }

    func contains(latitude: Double, longitude: Double) -> Bool {
        guard
            longitude >= minLongitude,
            longitude <= maxLongitude,
            latitude >= minLatitude,
            latitude <= maxLatitude
        else {
            return false
        }

        for polygon in polygons {
            guard Self.isInside(
                ring: polygon.rings[0],
                latitude: latitude,
                longitude: longitude
            ) else {
                continue
            }

            let isInsideHole = polygon.rings.dropFirst().contains { ring in
                Self.isInside(
                    ring: ring,
                    latitude: latitude,
                    longitude: longitude
                )
            }
            if !isInsideHole {
                return true
            }
        }
        return false
    }

    /// Ray casting with the same comparisons and axis order as Dart.
    private static func isInside(
        ring: [WidgetTownshipCoordinate],
        latitude: Double,
        longitude: Double
    ) -> Bool {
        var inside = false
        var previous = ring[ring.count - 1]

        for current in ring {
            if (current.latitude > latitude)
                != (previous.latitude > latitude),
                longitude
                    < (previous.longitude - current.longitude)
                    * (latitude - current.latitude)
                    / (previous.latitude - current.latitude)
                    + current.longitude
            {
                inside.toggle()
            }
            previous = current
        }
        return inside
    }
}

struct WidgetTownshipBoundaryTable: Sendable {
    private let shapesByCode: [String: WidgetTownshipShape]
    private let grid: WidgetTownshipGrid

    init(shapes: [WidgetTownshipShape]) throws {
        guard !shapes.isEmpty else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }

        let byCode = Dictionary(
            shapes.map { ($0.regionCode, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        guard byCode.count == shapes.count else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }

        shapesByCode = byCode
        grid = WidgetTownshipGrid(shapes: shapes)
    }

    static func decode(_ data: Data) throws -> Self {
        do {
            var reader = WidgetTownshipBinaryReader(data: data)
            let townCount = try reader.readCount(maximum: 10_000)
            guard townCount > 0 else {
                throw WidgetTownshipResourceError.invalidBoundaryData
            }

            var shapes: [WidgetTownshipShape] = []
            shapes.reserveCapacity(townCount)
            for _ in 0 ..< townCount {
                let codeLength = try reader.readCount(maximum: 16)
                let codeBytes = try reader.readBytes(count: codeLength)
                guard let regionCode = String(
                    bytes: codeBytes,
                    encoding: .ascii
                ) else {
                    throw WidgetTownshipResourceError.invalidBoundaryData
                }

                let polygonCount = try reader.readCount(maximum: 100_000)
                guard polygonCount > 0 else {
                    throw WidgetTownshipResourceError.invalidBoundaryData
                }
                var polygons: [WidgetTownshipPolygon] = []
                polygons.reserveCapacity(polygonCount)

                for _ in 0 ..< polygonCount {
                    let ringCount = try reader.readCount(maximum: 100_000)
                    guard ringCount > 0 else {
                        throw WidgetTownshipResourceError.invalidBoundaryData
                    }
                    var rings: [[WidgetTownshipCoordinate]] = []
                    rings.reserveCapacity(ringCount)

                    for _ in 0 ..< ringCount {
                        let pointCount = try reader.readCount(
                            maximum: 2_000_000
                        )
                        guard pointCount >= 3 else {
                            throw WidgetTownshipResourceError
                                .invalidBoundaryData
                        }

                        var points: [WidgetTownshipCoordinate] = []
                        points.reserveCapacity(pointCount)
                        var longitudeInteger = 0
                        var latitudeInteger = 0

                        for _ in 0 ..< pointCount {
                            longitudeInteger = try Self.add(
                                Self.unzigzag(try reader.readVarint()),
                                to: longitudeInteger
                            )
                            latitudeInteger = try Self.add(
                                Self.unzigzag(try reader.readVarint()),
                                to: latitudeInteger
                            )
                            points.append(
                                WidgetTownshipCoordinate(
                                    longitude:
                                        Double(longitudeInteger) / 10_000,
                                    latitude:
                                        Double(latitudeInteger) / 10_000
                                )
                            )
                        }
                        rings.append(points)
                    }
                    polygons.append(
                        try WidgetTownshipPolygon(rings: rings)
                    )
                }
                shapes.append(
                    try WidgetTownshipShape(
                        regionCode: regionCode,
                        polygons: polygons
                    )
                )
            }

            guard reader.isAtEnd else {
                throw WidgetTownshipResourceError.invalidBoundaryData
            }
            return try Self(shapes: shapes)
        } catch let error as WidgetTownshipResourceError {
            throw error
        } catch {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }
    }

    var regionCodes: Set<String> {
        Set(shapesByCode.keys)
    }

    func codeAt(latitude: Double, longitude: Double) -> String? {
        for regionCode in grid.candidates(
            latitude: latitude,
            longitude: longitude
        ) {
            if shapesByCode[regionCode]?.contains(
                latitude: latitude,
                longitude: longitude
            ) == true {
                return regionCode
            }
        }
        return nil
    }

    private static func unzigzag(_ value: UInt64) throws -> Int {
        guard value >> 1 <= UInt64(Int.max) else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }
        let magnitude = Int(value >> 1)
        return value & 1 == 0 ? magnitude : -magnitude - 1
    }

    private static func add(_ delta: Int, to value: Int) throws -> Int {
        let (sum, overflow) = value.addingReportingOverflow(delta)
        guard !overflow else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }
        return sum
    }
}

private struct WidgetTownshipGrid: Sendable {
    private static let cellSize = 0.05

    private let minLongitude: Double
    private let minLatitude: Double
    private let columnCount: Int
    private let rowCount: Int
    private let cells: [[String]?]

    init(shapes: [WidgetTownshipShape]) {
        let minLongitude = shapes.map(\.minLongitude).min()!
        let minLatitude = shapes.map(\.minLatitude).min()!
        let maxLongitude = shapes.map(\.maxLongitude).max()!
        let maxLatitude = shapes.map(\.maxLatitude).max()!
        let columnCount = Int(
            ceil((maxLongitude - minLongitude) / Self.cellSize)
        ) + 1
        let rowCount = Int(
            ceil((maxLatitude - minLatitude) / Self.cellSize)
        ) + 1
        var cells = Array<[String]?>(
            repeating: nil,
            count: columnCount * rowCount
        )

        for shape in shapes {
            let firstColumn = Int(floor(
                (shape.minLongitude - minLongitude) / Self.cellSize
            ))
            let lastColumn = Int(floor(
                (shape.maxLongitude - minLongitude) / Self.cellSize
            ))
            let firstRow = Int(floor(
                (shape.minLatitude - minLatitude) / Self.cellSize
            ))
            let lastRow = Int(floor(
                (shape.maxLatitude - minLatitude) / Self.cellSize
            ))
            for row in firstRow ... lastRow {
                for column in firstColumn ... lastColumn {
                    let index = row * columnCount + column
                    if cells[index] == nil {
                        cells[index] = []
                    }
                    cells[index]?.append(shape.regionCode)
                }
            }
        }

        self.minLongitude = minLongitude
        self.minLatitude = minLatitude
        self.columnCount = columnCount
        self.rowCount = rowCount
        self.cells = cells
    }

    func candidates(latitude: Double, longitude: Double) -> [String] {
        let column = Int(floor(
            (longitude - minLongitude) / Self.cellSize
        ))
        let row = Int(floor((latitude - minLatitude) / Self.cellSize))
        guard
            column >= 0,
            column < columnCount,
            row >= 0,
            row < rowCount
        else {
            return []
        }
        return cells[row * columnCount + column] ?? []
    }
}

private struct WidgetTownshipBinaryReader {
    private let bytes: [UInt8]
    private var position = 0

    init(data: Data) {
        bytes = Array(data)
    }

    var isAtEnd: Bool {
        position == bytes.count
    }

    mutating func readBytes(count: Int) throws -> ArraySlice<UInt8> {
        guard
            count >= 0,
            position <= bytes.count,
            count <= bytes.count - position
        else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }
        defer { position += count }
        return bytes[position ..< position + count]
    }

    mutating func readCount(maximum: Int) throws -> Int {
        let value = try readVarint()
        guard value <= UInt64(maximum) else {
            throw WidgetTownshipResourceError.invalidBoundaryData
        }
        return Int(value)
    }

    mutating func readVarint() throws -> UInt64 {
        var value: UInt64 = 0
        var shift: UInt64 = 0

        for _ in 0 ..< 10 {
            guard position < bytes.count else {
                throw WidgetTownshipResourceError.invalidBoundaryData
            }
            let byte = bytes[position]
            position += 1
            let payload = UInt64(byte & 0x7F)
            guard shift < 64, payload <= UInt64.max >> shift else {
                throw WidgetTownshipResourceError.invalidBoundaryData
            }
            value |= payload << shift
            if byte & 0x80 == 0 {
                return value
            }
            shift += 7
        }
        throw WidgetTownshipResourceError.invalidBoundaryData
    }
}

struct WidgetTownshipResolver: Sendable {
    let boundaries: WidgetTownshipBoundaryTable
    let directory: WidgetTownshipDirectory

    init(
        boundaries: WidgetTownshipBoundaryTable,
        directory: WidgetTownshipDirectory
    ) throws {
        guard boundaries.regionCodes == directory.regionCodes else {
            throw WidgetTownshipResourceError.incompatibleCodeSets
        }
        self.boundaries = boundaries
        self.directory = directory
    }

    /// Exact polygon first; nearest authoritative centroid only when no polygon
    /// contains the coordinate. Resource failures happen before this value can
    /// be constructed, so corrupt boundaries never degrade to nearest-only.
    func resolve(
        _ currentLocation: WidgetCurrentLocation
    ) -> WidgetResolvedWeatherLocation? {
        let exactCode = boundaries.codeAt(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude
        )
        let township: WidgetTownship?
        if let exactCode {
            township = directory.township(regionCode: exactCode)
        } else {
            township = directory.nearest(
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude
            )
        }

        guard let township else {
            return nil
        }
        return WidgetResolvedWeatherLocation(
            address: .currentLocation,
            regionCode: township.regionCode,
            regionName: township.displayName,
            latitude: township.latitude,
            longitude: township.longitude
        )
    }
}

struct WidgetTownshipResourceLoader: Sendable {
    private let directoryName: String
    private let boundaryName: String

    init(
        directoryName: String = "WidgetTownshipDirectory",
        boundaryName: String = "WidgetTownshipBoundaries"
    ) {
        self.directoryName = directoryName
        self.boundaryName = boundaryName
    }

    func load(bundle: Bundle) throws -> WidgetTownshipResolver {
        guard let directoryURL = bundle.url(
            forResource: directoryName,
            withExtension: "json"
        ) else {
            throw WidgetTownshipResourceError.missingResource(
                "\(directoryName).json"
            )
        }
        guard let boundaryURL = bundle.url(
            forResource: boundaryName,
            withExtension: "bin"
        ) else {
            throw WidgetTownshipResourceError.missingResource(
                "\(boundaryName).bin"
            )
        }

        let directoryData: Data
        let boundaryData: Data
        do {
            directoryData = try Data(contentsOf: directoryURL)
            boundaryData = try Data(contentsOf: boundaryURL)
        } catch {
            throw WidgetTownshipResourceError.missingResource(
                "Widget township resource"
            )
        }
        return try load(
            directoryData: directoryData,
            boundaryData: boundaryData
        )
    }

    func load(
        directoryData: Data,
        boundaryData: Data
    ) throws -> WidgetTownshipResolver {
        let directory = try WidgetTownshipDirectory.decode(directoryData)
        let boundaries = try WidgetTownshipBoundaryTable.decode(boundaryData)
        return try WidgetTownshipResolver(
            boundaries: boundaries,
            directory: directory
        )
    }
}

/// Swift static initialization is lazy and once-only. The immutable resolver
/// is therefore decoded at most once per Widget Extension process.
enum WidgetTownshipResolverRuntime {
    static let shared: WidgetTownshipResolver? = try?
        WidgetTownshipResourceLoader().load(bundle: .main)
}
