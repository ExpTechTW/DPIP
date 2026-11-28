import Foundation

/// DPIP's `estimateLocalShaking` (lib/features/earthquake/domain/
/// eew_local_estimate.dart), in Swift, for the EEW Live Activity widget.
///
/// A remotely started activity renders while the app is not running, so the
/// widget has to estimate the local intensity and the S-wave arrival itself.
/// This is the same arithmetic in the same order as the Dart — `EewEstimator.
/// locationInfo` for the intensity, `SeismicTravelTimeTable.sWaveTime` for the
/// arrival — so the widget and the app's own EEW card agree to the
/// millisecond; `EEWLocalEstimateTests` pins Dart-computed values, and the
/// shared payload vectors check it end to end. Change one, change both.
enum EEWLocalShaking {
    struct Estimate: Equatable {
        /// Discrete intensity, 0–9.
        let scale: Int
        /// Continuous intensity.
        let intensity: Double
        /// S-wave travel time from the origin, whole milliseconds.
        let sArrivalMs: Int
    }

    struct Point: Equatable {
        let latitude: Double
        let longitude: Double
    }

    static func estimate(
        magnitude: Double, depth: Double, epicenter: Point, observer: Point, table: EEWSWaveTable
    ) -> Estimate {
        let surfaceDistance = distanceMetres(epicenter, observer) / 1000
        let dist = (surfaceDistance * surfaceDistance + depth * depth).squareRoot()
        let pga = 1.657 * exp(1.533 * magnitude) * pow(dist, -1.607)
        var intensity = intensityFromPga(pga)
        if intensity >= 4.5 {
            intensity = pgvIntensity(
                epicentralKm: surfaceDistance, depth: depth, magW: magnitude,
                tenPowHalfMag: pow(10, 0.5 * magnitude))
        }
        // The arrival is measured on the epicentral distance, as the map's
        // wave circles are.
        let sArrivalMs = table.sWaveTimeMs(depth: depth, distance: surfaceDistance)
        return Estimate(scale: scale(intensity), intensity: intensity, sArrivalMs: Int(sArrivalMs.rounded()))
    }

    /// `LatLng.distanceTo`: haversine on a 6,378,137 m sphere.
    static func distanceMetres(_ from: Point, _ to: Point) -> Double {
        let earthRadius = 6_378_137.0
        let dLat = radians(to.latitude - from.latitude)
        let dLng = radians(to.longitude - from.longitude)
        let sinHalfLat = sin(dLat / 2)
        let sinHalfLng = sin(dLng / 2)
        let a = sinHalfLat * sinHalfLat
            + cos(radians(from.latitude)) * cos(radians(to.latitude)) * sinHalfLng * sinHalfLng
        let c = 2 * atan2(a.squareRoot(), (1 - a).squareRoot())
        return earthRadius * c
    }

    /// `Intensity.fromPga`. Written as log/ln10, not log10, as the Dart is.
    static func intensityFromPga(_ pga: Double) -> Double {
        2 * (log(pga) / ln10) + 0.7
    }

    /// `Intensity.toScale`.
    static func scale(_ value: Double) -> Int {
        if value < 0.5 { return 0 }
        if value < 1.5 { return 1 }
        if value < 2.5 { return 2 }
        if value < 3.5 { return 3 }
        if value < 4.5 { return 4 }
        if value < 5.0 { return 5 }
        if value < 5.5 { return 6 }
        if value < 6.0 { return 7 }
        if value < 6.5 { return 8 }
        return 9
    }

    /// `EewEstimator._pgvIntensity`.
    private static func pgvIntensity(
        epicentralKm: Double, depth: Double, magW: Double, tenPowHalfMag: Double
    ) -> Double {
        let long = tenPowHalfMag * 0.01412537544622754 / 2
        let hypocentralDistance = (depth * depth + epicentralKm * epicentralKm).squareRoot() - long
        let x = max(hypocentralDistance, 3.0)
        let log10Pgv600 = 0.58 * magW + 0.0038 * depth - 1.29
            - log(x + 0.0028 * tenPowHalfMag) / ln10 - 0.002 * x
        return 2.68 + 1.72 * (log10Pgv600 + 0.11727129565576426)
    }

    /// Dart's `math.ln10`.
    private static let ln10 = 2.302585092994046

    private static func radians(_ degrees: Double) -> Double { degrees * Double.pi / 180 }
}

/// The S-wave column of the CWA travel-time table, as the app packs it
/// (`lib/features/earthquake/data/s_wave_table_codec.dart` documents the
/// layout; keep the two in step). Memory-mapped: a lookup reads the depth row
/// it needs, never the whole table.
struct EEWSWaveTable {
    static let formatVersion: UInt16 = 1
    private static let magic: [UInt8] = Array("DPSW".utf8)

    private let data: Data
    let depths: [Int]
    let radii: [Double]
    private let dataOffset: Int

    init?(data: Data) {
        guard data.count >= 12, Array(data.prefix(4)) == Self.magic,
              Self.uint16(data, 4) == Self.formatVersion else { return nil }
        let depthCount = Int(Self.uint16(data, 6))
        let radiusCount = Int(Self.uint16(data, 8))
        let dataOffset = 12 + 2 * depthCount + 2 * radiusCount
        guard depthCount > 0, radiusCount > 0,
              data.count == dataOffset + 4 * depthCount * radiusCount else { return nil }
        self.data = data
        self.depths = (0..<depthCount).map { Int(Self.uint16(data, 12 + 2 * $0)) }
        self.radii = (0..<radiusCount).map { Double(Self.uint16(data, 12 + 2 * depthCount + 2 * $0)) }
        self.dataOffset = dataOffset
    }

    init?(contentsOf url: URL) {
        guard let data = try? Data(contentsOf: url, options: .alwaysMapped) else { return nil }
        self.init(data: data)
    }

    /// `SeismicTravelTimeTable.sWaveTime`: the S travel time (ms) to the
    /// epicentral [distance] (km) at [depth] (km), interpolated on the radius
    /// grid, 0 beyond its end. Its quirks are kept on purpose: a segment that
    /// interpolates to exactly 0 keeps walking, as the Dart loop does.
    func sWaveTimeMs(depth: Double, distance: Double) -> Double {
        let row = closestDepthIndex(depth)
        var time = 0.0
        var i = lowerBoundRadius(distance)
        while i < radii.count {
            if time == 0 && radii[i] >= distance {
                if i == 0 {
                    time = s(row, 0)
                } else {
                    let previous = s(row, i - 1)
                    time = previous + ((distance - radii[i - 1]) / (radii[i] - radii[i - 1])) * (s(row, i) - previous)
                }
            }
            if time != 0 { break }
            i += 1
        }
        return time * 1000
    }

    /// The tabulated depth nearest [depth]; a tie keeps the shallower one.
    func closestDepthIndex(_ depth: Double) -> Int {
        var lo = 0
        var hi = depths.count
        while lo < hi {
            let mid = (lo + hi) >> 1
            if Double(depths[mid]) < depth { lo = mid + 1 } else { hi = mid }
        }
        if lo <= 0 { return 0 }
        if lo >= depths.count { return depths.count - 1 }
        let before = Double(depths[lo - 1])
        let after = Double(depths[lo])
        return abs(after - depth) < abs(before - depth) ? lo : lo - 1
    }

    private func lowerBoundRadius(_ distance: Double) -> Int {
        var lo = 0
        var hi = radii.count
        while lo < hi {
            let mid = (lo + hi) >> 1
            if radii[mid] >= distance { hi = mid } else { lo = mid + 1 }
        }
        return lo
    }

    /// Seconds, as the double the Dart table holds: `ms / 1000` is the double
    /// nearest the JSON's three-decimal value, which is what parsing it gave.
    private func s(_ row: Int, _ column: Int) -> Double {
        Double(Self.uint32(data, dataOffset + 4 * (row * radii.count + column))) / 1000
    }

    private static func uint16(_ data: Data, _ offset: Int) -> UInt16 {
        data.withUnsafeBytes { UInt16(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self)) }
    }

    private static func uint32(_ data: Data, _ offset: Int) -> UInt32 {
        data.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self)) }
    }
}

/// Where the observer is: the app's last GPS fix, else the selected
/// township's centroid — the app's own EEW card resolution.
struct EEWObserver: Codable, Equatable {
    struct Coordinate: Codable, Equatable {
        let lat: Double
        let lng: Double
    }

    struct Town: Codable, Equatable {
        let code: String
        let lat: Double
        let lng: Double
    }

    var fix: Coordinate?
    var town: Town?

    var point: EEWLocalShaking.Point? {
        if let fix { return .init(latitude: fix.lat, longitude: fix.lng) }
        if let town { return .init(latitude: town.lat, longitude: town.lng) }
        return nil
    }
}

/// The App Group files the app writes for the widget
/// (`ios/Runner/EEWLiveActivityDataPlugin.swift`) and the widget reads.
struct EEWLiveActivityStore {
    static let appGroupIdentifier = "group.com.exptech.dpip.dpip.widgets"

    let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    /// The shared container's store, or nil when the App Group is unavailable.
    init?() {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) else { return nil }
        self.init(directory: container.appendingPathComponent("LiveActivity", isDirectory: true))
    }

    var tableURL: URL { directory.appendingPathComponent("s-wave-v\(EEWSWaveTable.formatVersion).bin") }
    var tableVersionURL: URL { directory.appendingPathComponent("s-wave.version") }
    var observerURL: URL { directory.appendingPathComponent("observer.json") }

    func table() -> EEWSWaveTable? { EEWSWaveTable(contentsOf: tableURL) }

    func observer() -> EEWObserver? {
        guard let data = try? Data(contentsOf: observerURL) else { return nil }
        return try? JSONDecoder().decode(EEWObserver.self, from: data)
    }

    func tableVersion() -> Int? {
        guard let data = try? Data(contentsOf: tableVersionURL) else { return nil }
        return Int(String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func writeTable(_ table: Data, version: Int) throws {
        guard EEWSWaveTable(data: table) != nil else { throw CocoaError(.fileWriteUnknown) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try table.write(to: tableURL, options: .atomic)
        try Data(String(version).utf8).write(to: tableVersionURL, options: .atomic)
    }

    func updateObserver(_ change: (inout EEWObserver) -> Void) throws {
        var observer = observer() ?? EEWObserver()
        change(&observer)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(observer).write(to: observerURL, options: .atomic)
    }
}
