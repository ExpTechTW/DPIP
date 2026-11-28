import CryptoKit
import XCTest

@testable import Runner

/// The Swift port of `estimateLocalShaking` and the packed S-wave table it
/// reads, checked against the Dart: values Dart computed, the byte layout
/// Dart writes, and the shared payload vectors.
@available(iOS 16.1, *)
final class EEWLocalEstimateTests: XCTestCase {
    /// 花蓮縣花蓮市's centroid (assets/location.json, code 970).
    private let hualien = EEWLocalShaking.Point(latitude: 23.9820651, longitude: 121.6067705)

    // MARK: - The packed table

    /// The Swift packing of the bundled JSON is byte-identical to the Dart
    /// `SWaveTableCodec`'s: the same size and the same SHA-256 that
    /// test/features/earthquake/data/s_wave_table_codec_test.dart pins.
    func testPackedTableMatchesTheDartCodec() throws {
        let bytes = try Self.packedBundledTable()
        XCTAssertEqual(bytes.count, 100_760)
        XCTAssertEqual(
            SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(),
            "0e6a27fe3a6a26d4343548270ea2d793d3405163d145ff7c70b96e4015e3be33")
        let table = try XCTUnwrap(EEWSWaveTable(data: bytes))
        XCTAssertEqual(table.depths.count, 106)
        XCTAssertEqual(table.radii.count, 236)
    }

    func testRefusesAnythingButTheCurrentLayout() throws {
        let bytes = try Self.packedBundledTable()
        XCTAssertNil(EEWSWaveTable(data: Data()))
        XCTAssertNil(EEWSWaveTable(data: bytes.prefix(bytes.count - 1)))
        XCTAssertNil(EEWSWaveTable(data: bytes + Data([0])))
        var wrongMagic = bytes
        wrongMagic[0] = 0x58
        XCTAssertNil(EEWSWaveTable(data: wrongMagic))
        var wrongVersion = bytes
        wrongVersion[4] = 2
        XCTAssertNil(EEWSWaveTable(data: wrongVersion))
    }

    /// `SeismicTravelTimeTable.sWaveTime`, Dart-computed on the bundled table:
    /// interpolation, the nearest depth (a tie keeps the shallower), a depth
    /// off either end, and 0 beyond the last radius.
    func testSWaveTimeMatchesDart() throws {
        let table = try XCTUnwrap(EEWSWaveTable(data: Self.packedBundledTable()))
        for (depth, distance, expected) in [
            (20.0, 0.0, 5757.0), (11, 3, 3152), (700, 2500, 0), (-5, 1, 351.5), (13, 7.5, 4211.749999999999),
        ] {
            XCTAssertEqual(table.sWaveTimeMs(depth: depth, distance: distance), expected, "\(depth) km, \(distance) km")
        }
        XCTAssertEqual(table.depths[table.closestDepthIndex(11)], 10)
        XCTAssertEqual(table.depths[table.closestDepthIndex(11.01)], 12)
        XCTAssertEqual(table.depths[table.closestDepthIndex(-3)], 0)
        XCTAssertEqual(table.depths[table.closestDepthIndex(9_999)], 700)
    }

    // MARK: - estimateLocalShaking

    /// Dart `estimateLocalShaking` at 花蓮市, on the bundled table: the
    /// continuous intensity to the last bit, the scale, the S travel time.
    func testEstimateMatchesDart() throws {
        let table = try XCTUnwrap(EEWSWaveTable(data: Self.packedBundledTable()))
        let cases: [(Double, Double, Double, Double, Int, Double, Int)] = [
            (23.95, 121.71, 5.8, 20, 4, 4.492975952847003, 6581),
            (23.95, 121.71, 4.6, 10, 3, 3.4900142058121295, 4484),
            (22.78, 121.38, 6.2, 20, 3, 2.524074693327278, 37716),
            (23.85, 121.62, 7.1, 15, 7, 5.9213613632304085, 5987),
            (23.95, 121.71, 5.7, 20, 4, 4.359821264695466, 6581),
            (23.98, 121.61, 5.0, 0, 5, 4.626749906293611, 141),
            (23.9820651, 121.6067705, 3.0, 11, 2, 1.7862495712862485, 3007),
            (25.5, 125.0, 6.0, 33, 1, 0.8225549648887801, 93092),
            (21.0, 118.0, 7.5, 700, 2, 1.695506814500233, 171857),
            (40.0, 140.0, 8.0, 10, 1, 0.8818584519723471, 0),
        ]
        for (lat, lng, magnitude, depth, scale, intensity, sMs) in cases {
            let estimate = EEWLocalShaking.estimate(
                magnitude: magnitude, depth: depth, epicenter: .init(latitude: lat, longitude: lng),
                observer: hualien, table: table)
            XCTAssertEqual(estimate.scale, scale, "\(lat),\(lng) M\(magnitude) \(depth) km")
            XCTAssertEqual(estimate.intensity, intensity, "\(lat),\(lng) M\(magnitude) \(depth) km")
            XCTAssertEqual(estimate.sArrivalMs, sMs, "\(lat),\(lng) M\(magnitude) \(depth) km")
        }
    }

    // MARK: - The App Group files

    func testStoreRoundTripsTheTableAndTheObserver() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = EEWLiveActivityStore(directory: directory)
        XCTAssertNil(store.table())
        XCTAssertNil(store.tableVersion())
        XCTAssertNil(store.observer())

        let bytes = try Self.packedBundledTable()
        XCTAssertThrowsError(try store.writeTable(Data([1, 2, 3]), version: 1))
        try store.writeTable(bytes, version: 426_000_900)
        XCTAssertEqual(store.tableVersion(), 426_000_900)
        XCTAssertEqual(store.table()?.depths.count, 106)

        try store.updateObserver { $0.town = .init(code: "970", lat: 23.98, lng: 121.6) }
        XCTAssertEqual(store.observer()?.point, .init(latitude: 23.98, longitude: 121.6))
        // A fix wins over the township, and writing one keeps the other.
        try store.updateObserver { $0.fix = .init(lat: 24.01, lng: 121.62) }
        XCTAssertEqual(store.observer()?.point, .init(latitude: 24.01, longitude: 121.62))
        XCTAssertEqual(store.observer()?.town?.code, "970")
        try store.updateObserver { $0.town = nil }
        XCTAssertEqual(store.observer(), EEWObserver(fix: .init(lat: 24.01, lng: 121.62), town: nil))
        XCTAssertNil(EEWObserver().point)
    }

    /// The widget's whole path without the app's files: the local intensity
    /// is 「—」 and the arrival 「未提供」, never a guess.
    func testWithoutTableOrObserverNothingIsEstimated() throws {
        let table = try XCTUnwrap(EEWSWaveTable(data: Self.packedBundledTable()))
        let d = "1|3|0|1795888105|23.95|121.71|花蓮縣近海|5.8|20|4|4||0"
        for (observer, table) in [(nil, table), (hualien, nil), (nil, nil)] as [(EEWLocalShaking.Point?, EEWSWaveTable?)] {
            let report = try XCTUnwrap(
                EEWActivityReport(provider: "trem", d: d, observer: observer, table: table, isStale: false))
            XCTAssertNil(report.localIntensity)
            XCTAssertEqual(report.arrival, .unavailable)
        }
        XCTAssertNil(EEWActivityReport(provider: "trem", d: "9|3", observer: hualien, table: table, isStale: false))
    }

    // MARK: - Shared vectors

    /// test/fixtures/live_activity/payload_vectors.json: the vectors the
    /// sender and both apps test against. Parsed fields, every display text,
    /// and the local intensity and arrival from the real Dart
    /// `estimateLocalShaking`, number for number — no tolerance.
    func testSharedPayloadVectors() throws {
        let url = Self.repositoryRoot.appendingPathComponent("test/fixtures/live_activity/payload_vectors.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Shared payload vectors not found at \(url.path)")
        }
        let file = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        XCTAssertEqual(file["format"] as? String, "dpip-live-activity-payload-vectors")
        XCTAssertEqual(file["formatVersion"] as? Int, 1)
        let location = try XCTUnwrap(file["location"] as? [String: Any])
        let observer = EEWLocalShaking.Point(
            latitude: try XCTUnwrap(location["lat"] as? Double), longitude: try XCTUnwrap(location["lng"] as? Double))
        let table = try XCTUnwrap(EEWSWaveTable(data: Self.packedBundledTable()))
        let strings = EEWContentStateTests.catalogStrings("zh-Hant")
        let vectors = try XCTUnwrap(file["vectors"] as? [[String: Any]])
        XCTAssertFalse(vectors.isEmpty)

        for vector in vectors {
            let name = try XCTUnwrap(vector["name"] as? String)
            let provider = try XCTUnwrap(vector["provider"] as? String)
            let d = try XCTUnwrap(vector["d"] as? String)
            let parsed = try XCTUnwrap(vector["parsed"] as? [String: Any])
            let expected = try XCTUnwrap(vector["expected"] as? [String: Any])
            let payload = try XCTUnwrap(EEWPayload(d, provider: provider), name)
            let fields = try XCTUnwrap((file["fields"] as? [String: [String]])?[provider], name)
            XCTAssertTrue(Set(fields).isSubset(of: Set(parsed.keys)), name)

            // Parsed fields; JSON null is "no value". Every key is checked, so
            // a field the file gains and this port does not know fails here.
            for (key, raw) in parsed {
                let value: Any? = raw is NSNull ? nil : raw
                switch key {
                case "version": XCTAssertEqual(value as? Int, 1, name)
                case "serial": XCTAssertEqual(value as? Int, payload.serial, name)
                case "flags": XCTAssertEqual(value as? Int, payload.flags.rawValue, name)
                case "alert": XCTAssertEqual(value as? Bool, payload.isAlert, name)
                case "final": XCTAssertEqual(value as? Bool, payload.isFinal, name)
                case "cancel": XCTAssertEqual(value as? Bool, payload.isCancelled, name)
                case "hasNsspe": XCTAssertEqual(value as? Bool, payload.flags.contains(.hasNsspe), name)
                case "originTime":
                    XCTAssertEqual((value as? Int).map { Date(timeIntervalSince1970: TimeInterval($0)) }, payload.origin, name)
                case "lat": XCTAssertEqual(value as? Double, payload.latitude, name)
                case "lng": XCTAssertEqual(value as? Double, payload.longitude, name)
                case "epicenter": XCTAssertEqual(value as? String, payload.epicenter, name)
                case "magnitude": XCTAssertEqual(value as? Double, payload.magnitude, name)
                case "depth": XCTAssertEqual(value as? Double, payload.depthKm, name)
                case "rk": XCTAssertEqual(value as? Int, payload.rk, name)
                case "maxEstimate": XCTAssertEqual(value as? Int, payload.maxIntensity, name)
                case "firstAlertSerial": XCTAssertEqual(value as? Int, payload.firstAlertSerial, name)
                case "localNsspe": XCTAssertEqual(value as? Int, payload.localNsspe, name)
                default: XCTFail("\(name): unknown parsed field \(key)")
                }
            }

            // Before the arrival, not stale: what the card shows while it
            // counts down.
            let estimate = EEWPresentation.localEstimate(for: payload, observer: observer, table: table)
            let report = EEWActivityReport(
                payload: payload, estimate: estimate, isStale: false, now: payload.origin ?? .distantPast,
                strings: strings)
            for (key, raw) in expected {
                let value: Any? = raw is NSNull ? nil : raw
                let text = value as? String
                let number = value as? Int
                switch key {
                case "kind": XCTAssertEqual(report.kindText, text, name)
                case "kindColor": XCTAssertEqual(String(format: "#%06x", report.style.background.hex), text, name)
                case "report": XCTAssertEqual(report.reportNumber, text, name)
                case "source": XCTAssertEqual(report.sourceText, text, name)
                case "precision": XCTAssertEqual(report.precision.map(strings.precision), text, name)
                case "epicenter": XCTAssertEqual(report.epicenter, text, name)
                case "magnitude": XCTAssertEqual(report.magnitude, text, name)
                case "depth": XCTAssertEqual(report.depth, text, name)
                case "maxEstimate": XCTAssertEqual(strings.intensity(report.maxIntensity), text, name)
                case "localIntensity": XCTAssertEqual(strings.intensity(report.localIntensity), text, name)
                case "localLabel": XCTAssertEqual(report.localLabel, text, name)
                case "localLevel": XCTAssertEqual(report.localIntensity, number, name)
                case "appEstimateLevel": XCTAssertEqual(estimate?.scale, number, name)
                case "sWaveTravelMs": XCTAssertEqual(estimate?.sArrivalMs, number, name)
                case "ring": XCTAssertEqual(report.localIsLive, value as? Bool, name)
                case "note": XCTAssertEqual(report.noteText, text, name)
                case "disclaimer": XCTAssertEqual(report.showsDisclaimer ? strings.disclaimer : nil, text, name)
                case "arrival":
                    switch report.arrival {
                    case .countdown(let arrival):
                        XCTAssertEqual(Int((arrival.timeIntervalSince1970 * 1000).rounded()), number, name)
                    case .unavailable, .cancelled:
                        XCTAssertEqual(report.strings.slot(report.arrival), text, name)
                    case .arrived:
                        XCTFail("\(name): arrived at its own origin")
                    }
                default: XCTFail("\(name): unknown expected field \(key)")
                }
            }
        }
    }

    // MARK: - Helpers

    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static var packed: Data?

    /// The bundled travel-time JSON packed the way the app packs it for the
    /// widget — a test-side copy of `SWaveTableCodec.encode`, which the hash
    /// test above holds to the Dart bytes.
    static func packedBundledTable() throws -> Data {
        if let packed { return packed }
        let assets = repositoryRoot.appendingPathComponent("assets")
        let gzipped = try XCTUnwrap(
            ["travel_time.json.Z", "travel_time.json.gz"]
                .map { assets.appendingPathComponent($0) }
                .first { FileManager.default.fileExists(atPath: $0.path) })
        let json = try gunzip(Data(contentsOf: gzipped))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: [[String: Double]]])
        let depths = object.keys.compactMap { Int($0) }.sorted()
        let first = try XCTUnwrap(object[String(depths[0])])
        let radii = first.map { Int($0["R"] ?? -1) }

        var data = Data("DPSW".utf8)
        func append16(_ value: Int) { withUnsafeBytes(of: UInt16(value).littleEndian) { data.append(contentsOf: $0) } }
        func append32(_ value: Int) { withUnsafeBytes(of: UInt32(value).littleEndian) { data.append(contentsOf: $0) } }
        append16(1)
        append16(depths.count)
        append16(radii.count)
        append16(0)
        depths.forEach(append16)
        radii.forEach(append16)
        for depth in depths {
            let rows = try XCTUnwrap(object[String(depth)])
            XCTAssertEqual(rows.map { Int($0["R"] ?? -1) }, radii)
            for row in rows { append32(Int(((row["S"] ?? 0) * 1000).rounded())) }
        }
        packed = data
        return data
    }

    /// gzip → bytes: the header (RFC 1952) off, raw DEFLATE inflated.
    private static func gunzip(_ data: Data) throws -> Data {
        let bytes = [UInt8](data)
        XCTAssertEqual(Array(bytes.prefix(3)), [0x1F, 0x8B, 8])
        let flags = bytes[3]
        var offset = 10
        if flags & 4 != 0 { offset += 2 + Int(bytes[offset]) + Int(bytes[offset + 1]) << 8 }
        if flags & 8 != 0 { offset = try XCTUnwrap(bytes[offset...].firstIndex(of: 0)) + 1 }
        if flags & 16 != 0 { offset = try XCTUnwrap(bytes[offset...].firstIndex(of: 0)) + 1 }
        if flags & 2 != 0 { offset += 2 }
        let deflated = Data(bytes[offset..<(bytes.count - 8)])
        return try (deflated as NSData).decompressed(using: .zlib) as Data
    }
}
