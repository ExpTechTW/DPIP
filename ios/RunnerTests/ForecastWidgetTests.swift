import Foundation
import WidgetKit
import SwiftUI
import UIKit
import XCTest
import AppIntents

final class ForecastRemoteDTOTests: XCTestCase {
    func testDecodesAllUsablePointsInAPIOrderAcrossMidnight() throws {
        let dto = try forecastDTO(
            times: ["bad", "23:00", "00:00", "01:00", "02:00", "03:00", "04:00"]
        )
        XCTAssertEqual(dto.updateTime, 1_790_336_400_000)
        XCTAssertEqual(dto.points.map(\.time),
                       ["23:00", "00:00", "01:00", "02:00", "03:00", "04:00"])
    }

    func testFewerThanFiveUsablePointsRemainUnchanged() throws {
        XCTAssertEqual(try forecastDTO(times: ["12:00", "13:00"]).points.map(\.time),
                       ["12:00", "13:00"])
        XCTAssertTrue(try forecastDTO(times: []).points.isEmpty)
    }

    func testMalformedTimeAndTemperatureAreSkipped() throws {
        let data = Data("""
        {"updateTime":1790336400000,"forecast":[
          {"time":"24:00","temperature":20,"weather":"晴","weatherCode":100,"pop":10},
          {"time":"12:60","temperature":20,"weather":"晴","weatherCode":100,"pop":10},
          {"time":"12:00","temperature":"bad","weather":"晴","weatherCode":100,"pop":10},
          {"time":"13:00","temperature":21,"weather":"晴","weatherCode":100,"pop":10}
        ]}
        """.utf8)
        let dto = try JSONDecoder().decode(ForecastRemoteDTO.self, from: data)
        XCTAssertEqual(dto.points.map(\.time), ["13:00"])
    }

    func testInvalidPopBecomesNilWithoutDiscardingPoint() throws {
        let data = Data("""
        {"updateTime":1790336400000,"forecast":[
          {"time":"10:00","temperature":20,"weather":"晴","weatherCode":100,"pop":-1},
          {"time":"11:00","temperature":21,"weather":"晴","weatherCode":100,"pop":101},
          {"time":"12:00","temperature":22,"weather":"晴","weatherCode":100,"pop":"bad"},
          {"time":"13:00","temperature":23,"weather":"晴","weatherCode":100,"pop":50}
        ]}
        """.utf8)
        let dto = try JSONDecoder().decode(ForecastRemoteDTO.self, from: data)
        XCTAssertEqual(dto.points.map(\.pop), [nil, nil, nil, 50])
    }

    func testIncompleteMiddlePointIsSkippedWithoutLosingLaterHours() throws {
        let data = Data("""
        {"updateTime":1790336400000,"forecast":[
          {"time":"09:00","temperature":20,"weather":"晴","weatherCode":100},
          {"time":"10:00","temperature":21,"weather":"晴"},
          {"time":"11:00","temperature":22,"weather":"晴","weatherCode":100},
          {"time":"12:00","temperature":23,"weather":"晴","weatherCode":100},
          {"time":"13:00","temperature":24,"weather":"晴","weatherCode":100},
          {"time":"14:00","temperature":25,"weather":"晴","weatherCode":100}
        ]}
        """.utf8)
        let dto = try JSONDecoder().decode(ForecastRemoteDTO.self, from: data)
        let selected = ForecastWidgetSelection.upcomingPoints(
            dto.points, at: instant("2026-09-25T00:30:00Z"), limit: 5
        )
        XCTAssertEqual(selected.map(\.time),
                       ["09:00", "11:00", "12:00", "13:00", "14:00"])
        XCTAssertNil(selected[0].pop)
    }

    func testMissingRequiredWeatherAndWhitespaceWeatherAreSkipped() throws {
        let data = Data("""
        {"updateTime":1790336400000,"forecast":[
          {"time":"09:00","temperature":20,"weather":"   ","weatherCode":100},
          {"time":"10:00","temperature":21,"weatherCode":100},
          {"time":"11:00","weather":"晴","weatherCode":100},
          {"time":"12:00","temperature":22,"weather":"晴","weatherCode":100}
        ]}
        """.utf8)
        let dto = try JSONDecoder().decode(ForecastRemoteDTO.self, from: data)
        XCTAssertEqual(dto.points.map(\.time), ["12:00"])
    }
}

final class ForecastWidgetSelectionTests: XCTestCase {
    func testOrdersClockLabelsByTaipeiFutureDistanceAcrossMidnight() {
        let points = forecastPoints(times: [
            "01:00", "23:00", "02:00", "00:00",
        ])
        let selected = ForecastWidgetSelection.upcomingPoints(
            points, at: instant("2026-09-25T14:30:00Z"), limit: 5
        )
        XCTAssertEqual(selected.map(\.time),
                       ["23:00", "00:00", "01:00", "02:00"])
    }

    func testExpiredHourIsNotTomorrowButMidnightHourIsUpcoming() {
        let selected = ForecastWidgetSelection.upcomingPoints(
            forecastPoints(times: ["09:00", "11:00", "10:00"]),
            at: instant("2026-09-25T02:30:00Z"), limit: 5
        )
        XCTAssertEqual(selected.map(\.time), ["11:00"])
        XCTAssertEqual(ForecastWidgetSelection.minutesAhead(
            for: "00:00", at: instant("2026-09-25T15:30:00Z")
        ), 30)
        XCTAssertNil(ForecastWidgetSelection.minutesAhead(
            for: "09:00", at: instant("2026-09-25T02:30:00Z")
        ))
        XCTAssertEqual(ForecastWidgetSelection.minutesAhead(
            for: "22:30", at: instant("2026-09-25T02:30:00Z")
        ), 12 * 60)
        XCTAssertNil(ForecastWidgetSelection.minutesAhead(
            for: "22:31", at: instant("2026-09-25T02:30:00Z")
        ))
    }

    func testSelectionUsesTaipeiEvenWhenDeviceTimezoneChanges() {
        let original = NSTimeZone.default
        defer { NSTimeZone.default = original }
        let date = instant("2026-09-25T15:30:00Z")
        for timezone in ["America/Los_Angeles", "Pacific/Auckland"] {
            NSTimeZone.default = TimeZone(identifier: timezone)!
            XCTAssertEqual(ForecastWidgetSelection.minutesAhead(
                for: "00:00", at: date
            ), 30)
            XCTAssertEqual(ForecastWidgetSelection.minutesAhead(
                for: "23:00", at: date
            ), 0)
        }
    }

    func testObservationSelectsStrictlyNextWholeTaipeiHour() {
        let cases = [
            ("2026-09-25T11:50:00Z", "20:00"),
            ("2026-09-25T12:00:00Z", "21:00"),
            ("2026-09-25T12:40:00Z", "21:00"),
            ("2026-09-25T12:50:00Z", "21:00"),
            ("2026-09-25T13:00:00Z", "22:00"),
            ("2026-09-25T15:50:00Z", "00:00"),
            ("2026-09-25T16:00:00Z", "01:00"),
        ]
        let points = forecastPoints(times: (0..<24).map { String(format: "%02d:00", $0) })
        for (timestamp, firstHour) in cases {
            let observation = instant(timestamp)
            let selected = ForecastWidgetSelection.upcomingPoints(
                points, at: observation.addingTimeInterval(60),
                observationTime: Int(observation.timeIntervalSince1970), limit: 5
            )
            XCTAssertEqual(selected.first?.time, firstHour, timestamp)
            XCTAssertEqual(selected.count, 5)
        }
    }

    func testRecentObservationWinsOverLaterSystemClockAcrossHourBoundary() {
        let observation = instant("2026-09-25T11:50:00Z") // 19:50 Taipei
        XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
            forecastPoints(times: ["19:00", "20:00", "21:00", "22:00"]),
            at: instant("2026-09-25T12:04:00Z"), // device/calibrated 20:04
            observationTime: Int(observation.timeIntervalSince1970), limit: 5
        ).map(\.time), ["20:00", "21:00", "22:00"])
    }

    func testMissingInvalidFutureAndStaleObservationsUseNextCalibratedHour() {
        let now = instant("2026-09-25T14:30:00Z") // 22:30 Taipei
        let observations: [Int?] = [
            nil, 0, -1, Int.max,
            Int(now.timeIntervalSince1970) + 1,
            Int(instant("2026-09-25T12:40:00Z").timeIntervalSince1970),
            Int(now.timeIntervalSince1970 * 1_000), // milliseconds are invalid seconds
        ]
        for observation in observations {
            XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
                forecastPoints(times: ["21:00", "22:00", "23:00", "00:00"]),
                at: now, observationTime: observation, limit: 5
            ).map(\.time), ["23:00", "00:00"], String(describing: observation))
        }
    }

    func testStaleBoundaryMatchesCurrentWeatherAtExactlyThirtyMinutes() {
        let observation = instant("2026-09-25T11:50:00Z")
        let points = forecastPoints(times: ["20:00", "21:00"])
        let timestamp = Int(observation.timeIntervalSince1970)
        XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
            points, at: observation.addingTimeInterval(1_799),
            observationTime: timestamp, limit: 5
        ).first?.time, "20:00")
        XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
            points, at: observation.addingTimeInterval(1_800),
            observationTime: timestamp, limit: 5
        ).map(\.time), ["21:00"])
    }

    func testObservationAndFallbackRollOverMidnightWithoutReusingPastHours() {
        let observation = instant("2026-09-25T15:50:00Z") // 23:50 Taipei
        let points = forecastPoints(times: ["23:00", "00:00", "01:00", "02:00"])
        for (timestamp, expected) in [
            ("2026-09-25T16:04:00Z", ["00:00", "01:00", "02:00"]),
            ("2026-09-25T16:30:00Z", ["01:00", "02:00"]),
        ] {
            XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
                points, at: instant(timestamp),
                observationTime: Int(observation.timeIntervalSince1970), limit: 5
            ).map(\.time), expected)
        }
    }

    func testMissingObservationSkipsCurrentBucketAndDoesNotInventMissingHours() {
        XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
            forecastPoints(times: ["19:00", "20:00", "23:00", "21:00", "00:00"]),
            at: instant("2026-09-25T12:04:00Z"), limit: 5
        ).map(\.time), ["21:00", "23:00", "00:00"])
    }

    func testMissingNextObservationHourUsesOnlyLaterSuppliedPoints() {
        let observation = instant("2026-09-25T12:40:00Z") // 20:40 Taipei
        XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
            forecastPoints(times: ["20:00", "00:00", "23:00", "22:00"]),
            at: observation.addingTimeInterval(60),
            observationTime: Int(observation.timeIntervalSince1970), limit: 5
        ).map(\.time), ["22:00", "23:00", "00:00"])
    }

    func testObservationSelectionPreservesTwelveHourHorizonAndStableAPITies() {
        let observation = instant("2026-09-25T12:04:00Z")
        let first = ForecastWidgetPoint(time: "21:00", temperature: 21,
                                        weather: "晴", weatherCode: 100, pop: nil)!
        let second = ForecastWidgetPoint(time: "21:00", temperature: 22,
                                         weather: "晴", weatherCode: 100, pop: nil)!
        let selected = ForecastWidgetSelection.upcomingPoints(
            [first, second] + forecastPoints(times: ["20:00", "08:04", "08:05", "08:00"]),
            at: observation.addingTimeInterval(60),
            observationTime: Int(observation.timeIntervalSince1970), limit: 5
        )
        XCTAssertEqual(selected.map(\.time), ["21:00", "21:00", "08:00", "08:04"])
        XCTAssertEqual(Array(selected.prefix(2)), [first, second])
        XCTAssertTrue(ForecastWidgetSelection.upcomingPoints(
            [first], at: observation, limit: 0
        ).isEmpty)
    }

    func testCalibratedClockDoesNotApplyEitherOffsetToObservationTwice() {
        let observation = Int(instant("2026-09-25T11:50:00Z").timeIntervalSince1970)
        for (deviceTime, offset) in [("11:59:00", 300_000), ("12:09:00", -300_000)] {
            let current = currentSnapshot(target: .saved(regionCode: "407"), offset: offset,
                                          observationTime: observation)
            let calibratedDate = CurrentWeatherWidgetTimeCalibration(snapshot: current)
                .calibratedDate(fromDeviceDate: instant("2026-09-25T\(deviceTime)Z"))
            XCTAssertEqual(calibratedDate, instant("2026-09-25T12:04:00Z"))
            XCTAssertEqual(ForecastWidgetSelection.upcomingPoints(
                forecastPoints(times: ["19:00", "20:00", "21:00"]),
                at: calibratedDate, observationTime: current.observationTime, limit: 5
            ).map(\.time), ["20:00", "21:00"])
        }
    }

    func testKeepsOnlyUsableUpcomingPointsAndDoesNotCreatePlaceholders() {
        let points = forecastPoints(times: ["08:00", "11:00", "12:00"])
        let selected = ForecastWidgetSelection.upcomingPoints(
            points, at: instant("2026-09-25T02:30:00Z"), limit: 5
        )
        XCTAssertEqual(selected.map(\.time), ["11:00", "12:00"])
    }

    func testSelectsNearestFiveFromMoreThanFiveValidPoints() {
        let points = forecastPoints(times: [
            "16:00", "13:00", "11:00", "15:00", "12:00", "14:00", "10:00",
        ])
        let selected = ForecastWidgetSelection.upcomingPoints(
            points, at: instant("2026-09-25T01:30:00Z"), limit: 5
        )
        XCTAssertEqual(selected.map(\.time),
                       ["10:00", "11:00", "12:00", "13:00", "14:00"])
    }

    func testMissingPoPDoesNotRemoveAnUpcomingPoint() {
        let point = ForecastWidgetPoint(
            time: "11:00", temperature: 22, weather: "晴",
            weatherCode: 100, pop: nil
        )!
        let selected = ForecastWidgetSelection.upcomingPoints(
            [point], at: instant("2026-09-25T02:30:00Z"), limit: 5
        )
        XCTAssertEqual(selected.count, 1)
        XCTAssertNil(selected[0].pop)
    }
}

final class ForecastClientTests: XCTestCase {
    private var session: URLSession!
    private var client: ForecastClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ForecastMockURLProtocol.self]
        session = URLSession(configuration: configuration)
        client = ForecastClient(session: session)
    }

    override func tearDown() {
        ForecastMockURLProtocol.handler = nil
        session.invalidateAndCancel()
        session = nil
        client = nil
        super.tearDown()
    }

    func testSuccessfulGETAndDecode() async throws {
        ForecastMockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString,
                "https://api.core-tnn1.exptech.dev/api/v5/meteor/weather/forecast/407")
            return (self.response(for: request, status: 200),
                    forecastJSON(times: ["23:00", "00:00"]))
        }
        let dto = try await client.fetch(regionCode: "407")
        XCTAssertEqual(dto.points.map(\.time), ["23:00", "00:00"])
    }

    func testRejectsInvalidRegionCodeBeforeRequest() {
        for code in ["40", "0407", "4A7", "٤٠٧", "../"] {
            XCTAssertThrowsError(try client.makeURL(regionCode: code))
        }
    }

    func testNon200Fails() async {
        ForecastMockURLProtocol.handler = { request in
            (self.response(for: request, status: 503), Data())
        }
        do {
            _ = try await client.fetch(regionCode: "407")
            XCTFail("Expected HTTP error")
        } catch let error as ForecastClientError {
            XCTAssertEqual(error, .httpStatus(503))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTimeoutFailsWithoutWaitingForWallTime() async {
        ForecastMockURLProtocol.handler = { request in
            XCTAssertEqual(request.timeoutInterval, 6)
            throw URLError(.timedOut)
        }
        do {
            _ = try await client.fetch(regionCode: "407")
            XCTFail("Expected timeout")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testOversizedResponseFails() async {
        ForecastMockURLProtocol.handler = { request in
            (self.response(for: request, status: 200), Data(repeating: 65,
                                                               count: 128 * 1024 + 1))
        }
        do {
            _ = try await client.fetch(regionCode: "407")
            XCTFail("Expected response-size error")
        } catch let error as ForecastClientError {
            XCTAssertEqual(error, .responseTooLarge)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func response(for request: URLRequest, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: status,
                        httpVersion: nil, headerFields: nil)!
    }
}

final class ForecastWidgetSnapshotTests: XCTestCase {
    func testSnapshotRetainsMoreThanFivePointsButRejectsEmpty() {
        XCTAssertNotNil(forecastSnapshot(times: [
            "10:00", "11:00", "12:00", "13:00", "14:00",
        ]))
        let sixPoints = ["10:00", "11:00", "12:00", "13:00", "14:00", "15:00"]
            .map {
                ForecastWidgetPoint(time: $0, temperature: 22,
                                    weather: "晴", weatherCode: 100,
                                    pop: 20)!
            }
        XCTAssertNotNil(ForecastWidgetSnapshot(
            sourceIdentifier: "region:407", regionCode: "407",
            updateTime: 1_790_336_400_000,
            receivedAt: 1_790_337_060_000,
            points: sixPoints
        ))
        XCTAssertNil(ForecastWidgetSnapshot(
            sourceIdentifier: "region:407", regionCode: "407",
            updateTime: 1_790_336_400_000,
            receivedAt: 1_790_337_060_000,
            points: []
        ))
    }

    func testSchemaV1RoundTripRetainsIdentityAndMillisecondTimes() throws {
        let original = forecastSnapshot()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ForecastWidgetSnapshot.self,
                                               from: data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.sourceIdentifier, "region:407")
        XCTAssertEqual(decoded.regionCode, "407")
        XCTAssertEqual(decoded.updateTime, 1_790_336_400_000)
        XCTAssertEqual(decoded.receivedAt, 1_790_337_060_000)
        XCTAssertEqual(decoded.points.map(\.time),
                       ["23:00", "00:00", "01:00", "02:00", "03:00"])
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data)
            as? [String: Any])
        let point = try XCTUnwrap((json["points"] as? [[String: Any]])?.first)
        XCTAssertNil(point["date"])
        XCTAssertNil(point["validAt"])
    }

    func testRejectsFutureSchemaAndSavedRegionMismatch() throws {
        let data = try JSONEncoder().encode(forecastSnapshot())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data)
            as? [String: Any])
        json["schemaVersion"] = 2
        XCTAssertThrowsError(try JSONDecoder().decode(
            ForecastWidgetSnapshot.self,
            from: JSONSerialization.data(withJSONObject: json)
        ))
        XCTAssertNil(ForecastWidgetSnapshot(
            sourceIdentifier: "region:407", regionCode: "242",
            updateTime: 1_790_336_400_000,
            receivedAt: 1_790_337_060_000,
            points: forecastSnapshot().points
        ))
    }
}

final class ForecastWidgetExpiryTests: XCTestCase {
    func testPublicationAgeBoundaries() {
        let publication = instant("2026-09-25T11:26:00Z")
        let snapshot = forecastSnapshot(updateTime: milliseconds("2026-09-25T11:26:00Z"),
                                        receivedAt: milliseconds("2026-09-25T11:29:00Z"))
        let cases: [(TimeInterval, ForecastWidgetExpiry.Freshness)] = [
            (0, .fresh), (29 * 60 + 59, .fresh), (30 * 60, .stale),
            (119 * 60 + 59, .stale), (120 * 60, .expired),
        ]
        for (age, expected) in cases {
            XCTAssertEqual(ForecastWidgetExpiry.freshness(
                of: snapshot, at: publication.addingTimeInterval(age)), expected)
            XCTAssertEqual(ForecastWidgetExpiry.isUsable(
                snapshot, at: publication.addingTimeInterval(age)), expected != .expired)
        }
        XCTAssertEqual(ForecastWidgetExpiry.staleDate(for: snapshot),
                       instant("2026-09-25T11:56:00Z"))
        XCTAssertEqual(ForecastWidgetExpiry.date(for: snapshot),
                       instant("2026-09-25T13:26:00Z"))
    }

    func testNextTaipeiHourAndReceiptDoNotExpirePublication() {
        let snapshot = forecastSnapshot(updateTime: milliseconds("2026-09-25T07:40:00Z"),
                                        receivedAt: milliseconds("2026-09-25T07:50:00Z"))
        let original = NSTimeZone.default
        defer { NSTimeZone.default = original }
        for zone in ["America/Los_Angeles", "Pacific/Auckland"] {
            NSTimeZone.default = TimeZone(identifier: zone)!
            XCTAssertEqual(ForecastWidgetExpiry.date(for: snapshot),
                           instant("2026-09-25T09:40:00Z"))
            XCTAssertTrue(ForecastWidgetExpiry.isUsable(snapshot, at: instant("2026-09-25T08:00:00Z")))
        }
    }

    func testPublicationBoundariesUseCalibratedClockForBothOffsets() {
        let snapshot = forecastSnapshot(updateTime: milliseconds("2026-09-25T07:10:00Z"))
        for offset in [-300_000, 300_000] {
            let correction = Double(offset) / 1_000
            let stale = instant("2026-09-25T07:40:00Z").addingTimeInterval(-correction)
            let expired = instant("2026-09-25T09:10:00Z").addingTimeInterval(-correction)
            XCTAssertEqual(ForecastWidgetExpiry.staleDate(for: snapshot,
                calibratedTimeOffsetMilliseconds: offset), stale)
            XCTAssertEqual(ForecastWidgetExpiry.date(for: snapshot,
                calibratedTimeOffsetMilliseconds: offset), expired)
            XCTAssertEqual(ForecastWidgetExpiry.freshness(of: snapshot, at: stale,
                calibratedTimeOffsetMilliseconds: offset), .stale)
            XCTAssertEqual(ForecastWidgetExpiry.freshness(of: snapshot, at: expired,
                calibratedTimeOffsetMilliseconds: offset), .expired)
        }
    }

    func testFutureAndInvalidDatesFailClosedWithoutUnboundedLifetime() {
        let publication = instant("2026-09-25T07:10:00Z")
        let snapshot = forecastSnapshot(updateTime: milliseconds("2026-09-25T07:10:00Z"))
        XCTAssertEqual(ForecastWidgetExpiry.freshness(of: snapshot,
            at: publication.addingTimeInterval(-120)), .fresh)
        XCTAssertEqual(ForecastWidgetExpiry.freshness(of: snapshot,
            at: publication.addingTimeInterval(-121)), .expired)
        XCTAssertEqual(ForecastWidgetExpiry.freshness(of: snapshot,
            at: Date(timeIntervalSince1970: .nan)), .expired)
        XCTAssertNil(ForecastWidgetSnapshot(sourceIdentifier: "region:407", regionCode: "407",
            updateTime: 0, receivedAt: snapshot.receivedAt, points: snapshot.points))
        XCTAssertNil(ForecastWidgetSnapshot(sourceIdentifier: "region:407", regionCode: "407",
            updateTime: -1, receivedAt: snapshot.receivedAt, points: snapshot.points))
        let distant = forecastSnapshot(updateTime: Int64.max)
        XCTAssertFalse(ForecastWidgetExpiry.isUsable(distant, at: publication))
        for offset in [-300_000, 300_000] {
            XCTAssertFalse(ForecastWidgetExpiry.isUsable(snapshot,
                at: publication.addingTimeInterval(-121 - Double(offset) / 1_000),
                calibratedTimeOffsetMilliseconds: offset))
        }
    }
}

final class ForecastWidgetSnapshotStoreTests: XCTestCase {
    func testTargetIsolationAndRegionMatching() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let saved = WidgetLocationTarget.saved(regionCode: "407")
        let other = WidgetLocationTarget.saved(regionCode: "242")
        let current = WidgetLocationTarget.currentLocation
        let date = instant("2026-09-25T07:21:00Z")
        let snapshot = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        XCTAssertTrue(try store.write(snapshot, for: saved))
        XCTAssertEqual(store.load(for: saved, regionCode: "407", at: date)?
            .points.first?.time, "23:00")
        XCTAssertNil(store.load(for: other, regionCode: "242", at: date))
        XCTAssertNil(store.load(for: saved, regionCode: "242", at: date))
        XCTAssertFalse(try store.write(snapshot, for: other))
        let otherSnapshot = forecastSnapshot(
            sourceIdentifier: "region:242", regionCode: "242",
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        XCTAssertTrue(try store.write(otherSnapshot, for: other))
        XCTAssertNotNil(store.load(for: other, regionCode: "242", at: date))
        XCTAssertNotNil(store.load(for: saved, regionCode: "407", at: date))

        let currentSnapshot = forecastSnapshot(
            sourceIdentifier: "current-location", regionCode: "407",
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        XCTAssertTrue(try store.write(currentSnapshot, for: current))
        XCTAssertNotNil(store.load(for: current, regionCode: "407", at: date))
        XCTAssertNil(store.load(for: current, regionCode: "242", at: date))
        XCTAssertNotEqual(store.snapshotURL(for: saved),
                          store.snapshotURL(for: current))
    }

    func testCorruptAndExpiredCacheAreRejected() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let snapshot = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        try store.write(snapshot, for: target)
        XCTAssertNil(store.load(for: target, regionCode: "407",
                                at: instant("2026-09-25T09:10:00Z")))
        let url = try XCTUnwrap(store.snapshotURL(for: target))
        try Data("broken".utf8).write(to: url, options: .atomic)
        XCTAssertNil(store.load(for: target, regionCode: "407",
                                at: instant("2026-09-25T07:21:00Z")))
        try Data(repeating: 65, count: 128 * 1024 + 1)
            .write(to: url, options: .atomic)
        XCTAssertNil(store.load(for: target, regionCode: "407",
                                at: instant("2026-09-25T07:21:00Z")))
    }

    func testCacheExpiryUsesCalibratedPublicationWithDeviceClockOffset() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let snapshot = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:26:00Z")
        )
        try store.write(snapshot, for: target)

        XCTAssertNotNil(store.load(
            for: target, regionCode: "407",
            at: instant("2026-09-25T09:14:59Z"),
            calibratedTimeOffsetMilliseconds: -300_000
        ))
        XCTAssertNil(store.load(
            for: target, regionCode: "407",
            at: instant("2026-09-25T09:15:00Z"),
            calibratedTimeOffsetMilliseconds: -300_000
        ))
    }
}

final class ForecastWidgetProviderTests: XCTestCase {
    func testForecastFamilyPolicySupportsOnlyMediumAndLarge() {
        XCTAssertFalse(ForecastWidgetFamilyPolicy.supportsForecast(.systemSmall))
        XCTAssertTrue(ForecastWidgetFamilyPolicy.supportsForecast(.systemMedium))
        XCTAssertTrue(ForecastWidgetFamilyPolicy.supportsForecast(.systemLarge))
        XCTAssertFalse(ForecastWidgetFamilyPolicy.supportsForecast(.systemExtraLarge))
    }

    func testMediumAndLargeUseTheSameVisibleSelection() {
        let forecast = forecastSnapshot(times: [
            "09:00", "13:00", "11:00", "15:00", "12:00", "14:00",
        ])
        let date = instant("2026-09-25T02:30:00Z")
        let medium = ForecastWidgetFamilyPolicy.visiblePoints(
            in: forecast, at: date, observationTime: nil, family: .systemMedium
        )
        let large = ForecastWidgetFamilyPolicy.visiblePoints(
            in: forecast, at: date, observationTime: nil, family: .systemLarge
        )
        XCTAssertEqual(medium, large)
        XCTAssertEqual(medium.map(\.time),
                       ["11:00", "12:00", "13:00", "14:00", "15:00"])
    }

    func testStaleObservationUsesNextCalibratedTaipeiHourWithDeviceClockOffset() {
        let deviceDate = instant("2026-09-25T02:30:00Z") // 10:30 Taipei
        let current = CurrentWeatherWidgetSnapshot(
            schemaVersion: 7,
            sourceIdentifier: "region:407",
            regionCode: "407",
            regionName: "測試地區",
            observationTime: Int(deviceDate.timeIntervalSince1970) - 3_600,
            stationName: "station",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: false,
            nextDayNightTransitionTime: 0,
            calibratedTimeOffsetMilliseconds: 3_600_000,
            temperature: 22,
            humidity: 50,
            rain: 0
        )
        let calibratedDate = CurrentWeatherWidgetTimeCalibration(
            snapshot: current
        ).calibratedDate(fromDeviceDate: deviceDate) // 11:30 Taipei
        let forecast = forecastSnapshot(
            updateTime: milliseconds("2026-09-24T00:00:00Z"),
            times: ["10:00", "11:00", "12:00"]
        )

        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let selected = ForecastWidgetFamilyPolicy.visiblePoints(
                in: forecast, at: calibratedDate, observationTime: current.observationTime, family: family
            )
            XCTAssertEqual(selected.map(\.time), ["12:00"])
        }
    }

    func testEntriesAlignMediumAndLargeForBothLocationKindsAndClockOffsets() {
        let cases = [
            ("2026-09-25T11:50:00Z", "2026-09-25T12:04:00Z", "20:00"),
            ("2026-09-25T12:00:00Z", "2026-09-25T12:01:00Z", "21:00"),
            ("2026-09-25T12:40:00Z", "2026-09-25T12:41:00Z", "21:00"),
            ("2026-09-25T12:50:00Z", "2026-09-25T12:51:00Z", "21:00"),
            ("2026-09-25T13:00:00Z", "2026-09-25T13:01:00Z", "22:00"),
            ("2026-09-25T15:50:00Z", "2026-09-25T16:04:00Z", "00:00"),
            ("2026-09-25T16:00:00Z", "2026-09-25T16:01:00Z", "01:00"),
        ]
        let originalZone = NSTimeZone.default
        defer { NSTimeZone.default = originalZone }
        for zone in ["Asia/Taipei", "America/Los_Angeles", "Pacific/Auckland"] {
            NSTimeZone.default = TimeZone(identifier: zone)!
            for target: WidgetLocationTarget in [.saved(regionCode: "407"), .currentLocation] {
                for offset in [-300_000, 0, 300_000] {
                    for (observed, calibrated, expected) in cases {
                        let timestamp = Int(instant(observed).timeIntervalSince1970)
                        let calibratedNow = instant(calibrated)
                        let deviceNow = calibratedNow.addingTimeInterval(-Double(offset) / 1_000)
                        let current = currentSnapshot(target: target, offset: offset,
                                                      observationTime: timestamp)
                        let forecast = forecastSnapshot(
                            sourceIdentifier: target.sourceIdentifier!,
                            updateTime: Int64(calibratedNow.timeIntervalSince1970 * 1_000),
                            receivedAt: Int64(deviceNow.timeIntervalSince1970 * 1_000),
                            times: (0..<24).map { String(format: "%02d:00", $0) }
                        )
                        let entry = DPIPWidgetEntry(date: deviceNow, snapshot: current,
                                                    isStale: false, isNight: false,
                                                    forecast: forecast, locationTarget: target)
                        let medium = entry.upcomingForecastPoints(for: .systemMedium)
                        XCTAssertEqual(medium.first?.time, expected, "\(zone) / \(observed) / \(offset)")
                        XCTAssertEqual(medium.count, 5)
                        XCTAssertEqual(medium, entry.upcomingForecastPoints(for: .systemLarge))
                        XCTAssertTrue(entry.upcomingForecastPoints(for: .systemSmall).isEmpty)
                        XCTAssertEqual(entry.snapshot?.observationTime, timestamp)
                    }
                }
            }
        }
    }

    func testFailedCurrentRefreshUsesStaleObservationFallbackWhileForecastStillRefreshes() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let now = instant("2026-09-25T14:30:00Z") // 22:30 Taipei
        let observation = Int(instant("2026-09-25T12:40:00Z").timeIntervalSince1970)
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let state = ForecastPlannerState(
                current: currentSnapshot(target: target, observationTime: observation),
                forecast: forecastSnapshot(updateTime: Int64(now.timeIntervalSince1970 * 1_000),
                                            receivedAt: Int64(now.timeIntervalSince1970 * 1_000),
                                            times: ["21:00", "22:00", "23:00", "00:00"])
            )
            let planner = DPIPWidgetTimelinePlanner(
                staleAfter: CurrentWeatherWidgetTimeline.defaultStaleAfter, refreshInterval: 20 * 60,
                loadSnapshot: { state.loadCurrent($0) },
                refreshSaved: { _ in .failed }, refreshCurrent: { .failed },
                loadForecast: { state.loadForecast($0, $1, $2) },
                refreshForecast: { await state.refreshForecast($0, $1) }, now: { now }
            )
            let plan = await planner.plan(for: target, family: family)
            XCTAssertTrue(plan.states[0].isStale)
            XCTAssertEqual(state.forecastRefreshCount, 1)
            let entry = DPIPWidgetEntry(date: now, snapshot: plan.snapshot,
                                        isStale: plan.states[0].isStale, isNight: false,
                                        forecast: plan.forecast(at: now), locationTarget: target)
            XCTAssertEqual(entry.upcomingForecastPoints(for: family).map(\.time), ["23:00", "00:00"])
            XCTAssertEqual(entry.snapshot?.observationTime, observation)
            XCTAssertEqual(plan.reloadDate, instant("2026-09-25T14:50:00Z"))
        }
    }

    func testSmallDoesNotRefreshForecast() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(current: currentSnapshot(target: target))
        let planner = makePlanner(state: state)
        _ = await planner.plan(for: target, family: .systemSmall)
        XCTAssertEqual(state.forecastRefreshCount, 0)
        XCTAssertTrue(state.requestedRegions.isEmpty)
    }

    func testMediumAndLargeEachRefreshForecast() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(current: currentSnapshot(target: target))
        let planner = makePlanner(state: state)
        _ = await planner.plan(for: target, family: .systemMedium)
        XCTAssertEqual(state.forecastRefreshCount, 1)
        XCTAssertEqual(state.requestedRegions, ["407"])
        _ = await planner.plan(for: target, family: .systemLarge)
        XCTAssertEqual(state.forecastRefreshCount, 2)
        XCTAssertEqual(state.requestedRegions, ["407", "407"])
    }

    func testMediumSnapshotReadsMatchingCacheWithoutNetworkRequest() {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target),
            forecast: forecastSnapshot(
                updateTime: milliseconds("2026-09-25T07:10:00Z"),
                receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        )
        let planner = makePlanner(state: state)
        let dependencies = DPIPWidgetProviderDependencies(
            loadSnapshot: { state.loadCurrent($0) },
            timelinePlanner: planner,
            loadForecast: { state.loadForecast($0, $1, $2) }
        )
        let forecast = dependencies.forecastSnapshot(
            for: target, currentSnapshot: state.loadCurrent(target),
            at: instant("2026-09-25T07:21:00Z"), family: .systemMedium
        )
        XCTAssertNotNil(forecast)
        XCTAssertEqual(state.forecastRefreshCount, 0)
    }

    func testMediumIndependentlyRefreshesAndAttachesForecastWithoutLarge() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let refreshed = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target),
            forecastAfterRefresh: refreshed
        )

        let plan = await makePlanner(state: state).plan(
            for: target, family: .systemMedium
        )

        XCTAssertEqual(state.forecastRefreshCount, 1)
        XCTAssertEqual(state.requestedRegions, ["407"])
        XCTAssertEqual(plan.forecast?.updateTime, refreshed.updateTime)
    }

    func testMediumForecastFailureKeepsCurrentAndValidCacheFallback() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target),
            forecast: forecastSnapshot(
                updateTime: milliseconds("2026-09-25T07:10:00Z"),
                receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        )
        let plan = await makePlanner(state: state).plan(
            for: target, family: .systemMedium
        )
        XCTAssertEqual(plan.snapshot?.regionCode, "407")
        XCTAssertNotNil(plan.forecast)
        let expiry = instant("2026-09-25T09:10:00Z")
        XCTAssertEqual(plan.states.count, 4)
        XCTAssertTrue(plan.states.contains { $0.date == expiry })
        XCTAssertNotNil(plan.forecast(at: plan.states[0].date))
        XCTAssertNil(plan.forecast(at: expiry))
        XCTAssertEqual(plan.snapshot?.stationName, "station")
    }

    func testMediumRejectsExpiredAndMismatchedCache() async {
        let target = WidgetLocationTarget.currentLocation
        let current = currentSnapshot(target: target, regionCode: "242")
        let state = ForecastPlannerState(
            current: current,
            forecast: forecastSnapshot(
                sourceIdentifier: "current-location", regionCode: "407",
                updateTime: milliseconds("2026-09-25T07:10:00Z"),
                receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        )
        let regionMismatch = await makePlanner(state: state).plan(
            for: target, family: .systemMedium
        )
        XCTAssertNil(regionMismatch.forecast)
        state.forecast = forecastSnapshot(
            sourceIdentifier: "region:242", regionCode: "242",
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        let sourceMismatch = await makePlanner(state: state).plan(
            for: target, family: .systemMedium
        )
        XCTAssertNil(sourceMismatch.forecast)
        state.forecast = forecastSnapshot(
            sourceIdentifier: "current-location", regionCode: "242",
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        let latePlanner = makePlanner(
            state: state, now: instant("2026-09-25T09:10:00Z")
        )
        let expired = await latePlanner.plan(for: target,
                                             family: .systemMedium)
        XCTAssertNil(expired.forecast)
    }

    func testLargeForecastFallbackAndExpiryBehaviorRemainsUnchanged() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target),
            forecast: forecastSnapshot(
                updateTime: milliseconds("2026-09-25T07:10:00Z"),
                receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        )

        let plan = await makePlanner(state: state).plan(
            for: target, family: .systemLarge
        )

        let expiry = instant("2026-09-25T09:10:00Z")
        XCTAssertEqual(state.forecastRefreshCount, 1)
        XCTAssertNotNil(plan.forecast)
        XCTAssertTrue(plan.states.contains { $0.date == expiry })
        XCTAssertNil(plan.forecast(at: expiry))
    }

    func testLateCurrentLocationResponseForAIsNotWrittenAfterB() async {
        let target = WidgetLocationTarget.currentLocation
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target, regionCode: "407"))
        let gate = AsyncOperationGate()
        let fetchStarted = expectation(description: "Forecast fetch started")
        let dto = try! forecastDTO(times: ["23:00"])
        let service = ForecastWidgetRefreshService(
            fetch: { _ in
                fetchStarted.fulfill()
                await gate.wait()
                return dto
            },
            loadCurrent: { state.loadCurrent($0) },
            savedIsResolved: { _ in true },
            write: { snapshot, _ in state.forecast = snapshot; return true },
            now: { instant("2026-09-25T07:21:00Z") }
        )
        let task = Task { await service.refresh(target: target,
                                                regionCode: "407") }
        await fulfillment(of: [fetchStarted], timeout: 5)
        state.current = currentSnapshot(target: target, regionCode: "242")
        // Release even after expectation timeout; open also covers a late waiter.
        await gate.open()
        await task.value
        XCTAssertNil(state.forecast)
    }

    func testRefreshStoresAllValidPointsForTimelineSelection() async throws {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(current: currentSnapshot(target: target))
        let json = forecastJSON(times: [
            "14:00", "16:00", "18:00", "17:00", "19:00", "20:00", "21:00",
        ])
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: Any])
        payload["updateTime"] = milliseconds("2026-09-25T07:10:00Z")
        let dto = try JSONDecoder().decode(ForecastRemoteDTO.self,
            from: JSONSerialization.data(withJSONObject: payload))
        let date = instant("2026-09-25T07:21:00Z")
        let service = ForecastWidgetRefreshService(
            fetch: { _ in dto },
            loadCurrent: { state.loadCurrent($0) },
            savedIsResolved: { _ in true },
            write: { snapshot, _ in state.forecast = snapshot; return true },
            now: { date }
        )

        await service.refresh(target: target, regionCode: "407")

        let stored = try XCTUnwrap(state.forecast)
        XCTAssertEqual(stored.points.count, 7)
        XCTAssertEqual(ForecastWidgetFamilyPolicy.visiblePoints(
            in: stored, at: date, observationTime: state.current?.observationTime, family: .systemMedium
        ).map(\.time), ["16:00", "17:00", "18:00", "19:00", "20:00"])
    }

    func testUnresolvedSavedTargetNeverStartsForecastRequest() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(current: currentSnapshot(target: target))
        let calls = ForecastCallCounter()
        let service = ForecastWidgetRefreshService(
            fetch: { _ in
                calls.increment()
                return try forecastDTO(times: ["12:00"])
            },
            loadCurrent: { state.loadCurrent($0) },
            savedIsResolved: { _ in false },
            write: { _, _ in true },
            now: { instant("2026-09-25T07:21:00Z") }
        )
        await service.refresh(target: target, regionCode: "407")
        XCTAssertEqual(calls.count, 0)
    }

    private func makePlanner(
        state: ForecastPlannerState,
        now date: Date = instant("2026-09-25T07:21:00Z")
    ) -> DPIPWidgetTimelinePlanner {
        DPIPWidgetTimelinePlanner(
            staleAfter: 30 * 60,
            refreshInterval: 20 * 60,
            loadSnapshot: { state.loadCurrent($0) },
            refreshSaved: { _ in .failed },
            refreshCurrent: { .failed },
            loadForecast: { state.loadForecast($0, $1, $2) },
            refreshForecast: { await state.refreshForecast($0, $1) },
            now: { date }
        )
    }
}

final class ForecastWidgetGalleryPreviewTests: XCTestCase {
    private let date = instant("2026-09-25T07:21:00Z") // 15:21 Taipei
    private let target = WidgetLocationTarget.saved(regionCode: "407")

    func testFirstGalleryPreviewWithoutForecastUsesCompleteSampleForMediumAndLarge() throws {
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let state = ForecastPlannerState(current: currentSnapshot(target: target))
            let content = dependencies(state).snapshotContent(
                for: target, at: date, family: family, isPreview: true
            )
            let current = try XCTUnwrap(content.snapshot)
            let forecast = try XCTUnwrap(content.forecast)
            // Both sides come from the sample; no real observation is mixed in.
            XCTAssertEqual(current.temperature, 28)
            XCTAssertEqual(current.apparentTemperature, 30)
            XCTAssertNotEqual(current.stationName, "station")
            XCTAssertEqual(current.sourceIdentifier, forecast.sourceIdentifier)
            XCTAssertEqual(current.regionCode, forecast.regionCode)
            XCTAssertEqual(current.observationTime, Int(date.timeIntervalSince1970))
            XCTAssertEqual(forecast.updateTime, Int64(date.timeIntervalSince1970 * 1_000))
            XCTAssertEqual(ForecastWidgetFamilyPolicy.visiblePoints(
                in: forecast, at: date, observationTime: current.observationTime, family: family
            ).map(\.time), ["16:00", "17:00", "18:00", "19:00", "20:00"])
            XCTAssertEqual(state.forecastRefreshCount, 0)
            XCTAssertNil(state.forecast)
            XCTAssertEqual(state.current?.temperature, 22)
        }
    }

    func testGalleryWithoutAnyWeatherCacheStillHasCompleteSample() {
        let content = dependencies(ForecastPlannerState(current: nil)).snapshotContent(
            for: target, at: date, family: .systemMedium, isPreview: true
        )
        XCTAssertNotNil(content.snapshot)
        XCTAssertEqual(content.forecast?.points.count, 5)
    }

    func testGalleryPrefersMatchingValidForecastCacheForBothFamilies() {
        let forecast = freshForecast(times: ["16:00", "17:00"])
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target), forecast: forecast
        )
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let content = dependencies(state).snapshotContent(
                for: target, at: date, family: family, isPreview: true
            )
            XCTAssertEqual(content.snapshot?.stationName, "station")
            XCTAssertEqual(content.snapshot?.temperature, 22)
            XCTAssertEqual(content.forecast?.points, forecast.points)
            XCTAssertEqual(content.forecast?.updateTime, forecast.updateTime)
        }
        XCTAssertEqual(state.forecastRefreshCount, 0)
    }

    func testGalleryWithExpiredForecastUsesWholeSample() {
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target),
            forecast: forecastSnapshot(
                updateTime: milliseconds("2026-09-25T05:00:00Z"),
                receivedAt: milliseconds("2026-09-25T05:00:00Z"),
                times: ["16:00"]
            )
        )
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let content = dependencies(state).snapshotContent(
                for: target, at: date, family: family, isPreview: true
            )
            XCTAssertEqual(content.snapshot?.temperature, 28)
            XCTAssertEqual(content.forecast?.points.count, 5)
        }
    }

    func testGalleryWithFreshCacheButNoVisibleHoursUsesWholeSample() {
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target),
            forecast: freshForecast(times: ["13:00", "14:00"])
        )
        let content = dependencies(state).snapshotContent(
            for: target, at: date, family: .systemMedium, isPreview: true
        )
        XCTAssertEqual(content.snapshot?.temperature, 28)
        XCTAssertEqual(content.forecast?.points.count, 5)
    }

    func testSmallGalleryKeepsMatchingCurrentWeatherAndNeverGainsForecast() {
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target), forecast: freshForecast()
        )
        let content = dependencies(state).snapshotContent(
            for: target, at: date, family: .systemSmall, isPreview: true
        )
        XCTAssertEqual(content.snapshot?.temperature, 22)
        XCTAssertEqual(content.snapshot?.stationName, "station")
        XCTAssertNil(content.forecast)
        XCTAssertEqual(state.forecastRefreshCount, 0)
    }

    func testSmallGalleryWithoutMatchingCurrentWeatherUsesSampleWithoutForecast() {
        let currentTarget = WidgetLocationTarget.currentLocation
        let states = [
            ForecastPlannerState(current: nil),
            // A cached snapshot for a different location must not be shown.
            ForecastPlannerState(current: currentSnapshot(target: target)),
        ]
        for (index, state) in states.enumerated() {
            let requested = index == 0 ? target : currentTarget
            let content = dependencies(state).snapshotContent(
                for: requested, at: date, family: .systemSmall, isPreview: true
            )
            XCTAssertEqual(content.snapshot?.temperature, 28)
            XCTAssertEqual(content.snapshot?.sourceIdentifier, "region:407")
            XCTAssertNotEqual(content.snapshot?.stationName, "station")
            XCTAssertNil(content.forecast)
            XCTAssertEqual(state.forecastRefreshCount, 0)
        }
    }

    func testSmallSampleStaysOutOfNormalSnapshotsAndInvalidTargets() {
        let normal = dependencies(ForecastPlannerState(current: nil)).snapshotContent(
            for: target, at: date, family: .systemSmall, isPreview: false
        )
        XCTAssertNil(normal.snapshot)
        let invalid = dependencies(ForecastPlannerState(current: nil)).snapshotContent(
            for: .invalid(identifier: "bad"), at: date,
            family: .systemSmall, isPreview: true
        )
        XCTAssertNil(invalid.snapshot)
    }

    func testSampleNeverAppearsInNormalSnapshotsOrTimelinePlans() async {
        for current in [currentSnapshot(target: target), nil] {
            for family: WidgetFamily in [.systemMedium, .systemLarge] {
                let state = ForecastPlannerState(current: current)
                let deps = dependencies(state)
                let gallery = deps.snapshotContent(
                    for: target, at: date, family: family, isPreview: true
                )
                XCTAssertEqual(gallery.forecast?.points.count, 5)
                let normal = deps.snapshotContent(
                    for: target, at: date, family: family, isPreview: false
                )
                XCTAssertEqual(normal.snapshot?.temperature, current?.temperature)
                XCTAssertNil(normal.forecast)
                let plan = await deps.timelinePlanner.plan(for: target, family: family)
                XCTAssertEqual(plan.snapshot?.temperature, current?.temperature)
                XCTAssertNil(plan.forecast)
                for entry in plan.states {
                    XCTAssertNil(plan.forecast(at: entry.date))
                }
            }
        }
    }

    func testLocationSwitchRejectsPreviousTownshipAndSavedTargetForecasts() {
        let currentTarget = WidgetLocationTarget.currentLocation
        let state = ForecastPlannerState(
            current: currentSnapshot(target: currentTarget, regionCode: "242"),
            forecast: freshForecast(source: "current-location", region: "407")
        )
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let content = dependencies(state).snapshotContent(
                for: currentTarget, at: date, family: family, isPreview: true
            )
            // A complete labelled sample replaces both halves, never town B
            // weather plus town A forecast.
            XCTAssertNotEqual(content.snapshot?.stationName, "station")
            XCTAssertEqual(content.snapshot?.sourceIdentifier, "region:407")
            XCTAssertEqual(content.snapshot?.sourceIdentifier, content.forecast?.sourceIdentifier)
            state.forecast = freshForecast(source: "region:242", region: "242")
            let wrongSource = dependencies(state).snapshotContent(
                for: currentTarget, at: date, family: family, isPreview: true
            )
            XCTAssertNotEqual(wrongSource.snapshot?.stationName, "station")
            state.forecast = freshForecast(source: "current-location", region: "242")
            let matching = dependencies(state).snapshotContent(
                for: currentTarget, at: date, family: family, isPreview: true
            )
            XCTAssertEqual(matching.snapshot?.regionCode, "242")
            XCTAssertEqual(matching.snapshot?.stationName, "station")
            XCTAssertEqual(matching.forecast?.regionCode, "242")
            state.forecast = freshForecast(source: "current-location", region: "407")
        }
    }

    func testInvalidTargetDoesNotGainSampleOrOtherLocationData() {
        let content = dependencies(ForecastPlannerState(current: nil)).snapshotContent(
            for: .invalid(identifier: "bad"), at: date,
            family: .systemMedium, isPreview: true
        )
        XCTAssertNil(content.snapshot)
        XCTAssertNil(content.forecast)
    }

    func testRelativePreviewHoursAcrossDayAndMidnightIgnoreDeviceTimezone() throws {
        let original = NSTimeZone.default
        defer { NSTimeZone.default = original }
        let cases: [(String, [String], Bool)] = [
            ("2026-09-25T00:30:00Z", ["09:00", "10:00", "11:00", "12:00", "13:00"], false),
            ("2026-09-25T07:21:00Z", ["16:00", "17:00", "18:00", "19:00", "20:00"], false),
            ("2026-09-25T12:30:00Z", ["21:00", "22:00", "23:00", "00:00", "01:00"], true),
            ("2026-09-25T15:59:59Z", ["00:00", "01:00", "02:00", "03:00", "04:00"], true),
            ("2026-09-25T16:00:00Z", ["01:00", "02:00", "03:00", "04:00", "05:00"], true),
        ]
        for zone in ["Asia/Taipei", "America/Los_Angeles", "Pacific/Kiritimati"] {
            NSTimeZone.default = TimeZone(identifier: zone)!
            for (instantString, expected, night) in cases {
                let now = instant(instantString)
                let content = DPIPWidgetGalleryPreview.sample(at: now)
                let current = try XCTUnwrap(content.snapshot)
                let forecast = try XCTUnwrap(content.forecast)
                XCTAssertEqual(current.isNight, night)
                XCTAssertGreaterThan(Double(current.nextDayNightTransitionTime), now.timeIntervalSince1970)
                XCTAssertTrue(ForecastWidgetExpiry.isUsable(forecast, at: now))
                for family: WidgetFamily in [.systemMedium, .systemLarge] {
                    XCTAssertEqual(ForecastWidgetFamilyPolicy.visiblePoints(
                        in: forecast, at: now, observationTime: current.observationTime, family: family
                    ).map(\.time), expected, "\(zone) / \(instantString)")
                }
            }
        }
    }

    func testGallerySampleNeverWritesToPersistentStorage() throws {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: container) }
        let store = WidgetSnapshotStore(containerURL: container)
        let forecasts = ForecastWidgetSnapshotStore(containerURL: container)
        let current = currentSnapshot(target: target)
        _ = try CurrentWeatherWidgetTestFixtures.seed(
            current, at: .saved(regionCode: "407"), containerURL: container
        )
        let deps = DPIPWidgetProviderDependencies(
            loadSnapshot: { store.loadCurrentWeatherSnapshot(for: $0) },
            timelinePlanner: dependencies(ForecastPlannerState(current: nil)).timelinePlanner,
            loadForecast: { forecasts.load(for: $0, regionCode: $1, at: $2) }
        )
        // Include a stale cache file as well as the initially absent cache.
        for stale in [false, true] {
            if stale {
                try forecasts.write(forecastSnapshot(
                    updateTime: milliseconds("2026-09-25T06:00:00Z"),
                    receivedAt: milliseconds("2026-09-25T06:00:00Z")
                ), for: target)
            }
            let before = try persistedFiles(in: container)
            for family: WidgetFamily in [.systemMedium, .systemLarge] {
                let content = deps.snapshotContent(
                    for: target, at: date, family: family, isPreview: true
                )
                XCTAssertEqual(content.forecast?.points.count, 5)
                XCTAssertEqual(content.snapshot?.temperature, 28)
            }
            XCTAssertEqual(try persistedFiles(in: container), before)
        }
    }

    private func persistedFiles(in directory: URL) throws -> [String: Data] {
        let urls = FileManager.default.enumerator(
            at: directory, includingPropertiesForKeys: [.isRegularFileKey]
        )!.allObjects as! [URL]
        return try Dictionary(uniqueKeysWithValues: urls.filter {
            try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
        }.map { ($0.path, try Data(contentsOf: $0)) })
    }

    private func dependencies(_ state: ForecastPlannerState) -> DPIPWidgetProviderDependencies {
        let now = date
        return DPIPWidgetProviderDependencies(
            loadSnapshot: { state.loadCurrent($0) },
            timelinePlanner: DPIPWidgetTimelinePlanner(
                staleAfter: 30 * 60, refreshInterval: 20 * 60,
                loadSnapshot: { state.loadCurrent($0) },
                refreshSaved: { _ in .failed }, refreshCurrent: { .failed },
                loadForecast: { state.loadForecast($0, $1, $2) },
                refreshForecast: { await state.refreshForecast($0, $1) },
                now: { now }
            ),
            loadForecast: { state.loadForecast($0, $1, $2) }
        )
    }

    private func freshForecast(
        source: String = "region:407", region: String = "407",
        times: [String] = ["16:00", "17:00", "18:00", "19:00", "20:00"]
    ) -> ForecastWidgetSnapshot {
        forecastSnapshot(
            sourceIdentifier: source, regionCode: region,
            updateTime: Int64(date.timeIntervalSince1970 * 1_000),
            receivedAt: Int64(date.timeIntervalSince1970 * 1_000), times: times
        )
    }
}

private final class ForecastCallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var count: Int { lock.withLock { value } }
    func increment() { lock.withLock { value += 1 } }
}

private final class ForecastPlannerState: @unchecked Sendable {
    private let lock = NSLock()
    private var storedCurrent: CurrentWeatherWidgetSnapshot?
    private var storedForecast: ForecastWidgetSnapshot?
    private let forecastAfterRefresh: ForecastWidgetSnapshot?
    private var regions: [String] = []

    init(current: CurrentWeatherWidgetSnapshot?,
         forecast: ForecastWidgetSnapshot? = nil,
         forecastAfterRefresh: ForecastWidgetSnapshot? = nil) {
        storedCurrent = current
        storedForecast = forecast
        self.forecastAfterRefresh = forecastAfterRefresh
    }

    var current: CurrentWeatherWidgetSnapshot? {
        get { lock.withLock { storedCurrent } }
        set { lock.withLock { storedCurrent = newValue } }
    }
    var forecast: ForecastWidgetSnapshot? {
        get { lock.withLock { storedForecast } }
        set { lock.withLock { storedForecast = newValue } }
    }
    var forecastRefreshCount: Int { lock.withLock { regions.count } }
    var requestedRegions: [String] { lock.withLock { regions } }

    func loadCurrent(_ target: WidgetLocationTarget)
        -> CurrentWeatherWidgetSnapshot? {
        current
    }

    func loadForecast(_ target: WidgetLocationTarget,
                      _ regionCode: String,
                      _ date: Date) -> ForecastWidgetSnapshot? {
        guard let forecast,
              forecast.sourceIdentifier == target.sourceIdentifier,
              forecast.regionCode == regionCode,
              ForecastWidgetExpiry.isUsable(
                  forecast, at: date,
                  calibratedTimeOffsetMilliseconds:
                      current?.calibratedTimeOffsetMilliseconds ?? 0
              ) else {
            return nil
        }
        return forecast
    }

    func refreshForecast(_ target: WidgetLocationTarget,
                         _ regionCode: String) async {
        lock.withLock {
            regions.append(regionCode)
            if let forecastAfterRefresh {
                storedForecast = forecastAfterRefresh
            }
        }
    }
}

private final class ForecastMockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (URLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    override func startLoading() {
        do {
            guard let handler = Self.handler else {
                throw URLError(.badServerResponse)
            }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response,
                                cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

private func forecastDTO(times: [String]) throws -> ForecastRemoteDTO {
    try JSONDecoder().decode(ForecastRemoteDTO.self,
                             from: forecastJSON(times: times))
}

private func forecastJSON(times: [String]) -> Data {
    let points = times.map { time in
        ["time": time, "temperature": 22, "weather": "晴",
         "weatherCode": 100, "pop": 20] as [String: Any]
    }
    return try! JSONSerialization.data(withJSONObject: [
        "updateTime": 1_790_336_400_000 as Int64,
        "forecast": points,
    ])
}

private func forecastSnapshot(
    sourceIdentifier: String = "region:407",
    regionCode: String = "407",
    updateTime: Int64 = 1_790_336_400_000,
    receivedAt: Int64 = 1_790_337_060_000,
    times: [String] = ["23:00", "00:00", "01:00", "02:00", "03:00"]
) -> ForecastWidgetSnapshot {
    ForecastWidgetSnapshot(
        sourceIdentifier: sourceIdentifier,
        regionCode: regionCode,
        updateTime: updateTime,
        receivedAt: receivedAt,
        points: times.map {
            ForecastWidgetPoint(time: $0, temperature: 22,
                                weather: "晴", weatherCode: 100,
                                pop: 20)!
        }
    )!
}

private func forecastPoints(times: [String]) -> [ForecastWidgetPoint] {
    times.map {
        ForecastWidgetPoint(time: $0, temperature: 22,
                            weather: "晴", weatherCode: 100, pop: 20)!
    }
}

private func currentSnapshot(target: WidgetLocationTarget,
                             regionCode: String = "407",
                             offset: Int = 0,
                             observationTime: Int? = nil)
    -> CurrentWeatherWidgetSnapshot {
    CurrentWeatherWidgetSnapshot(
        schemaVersion: 7,
        sourceIdentifier: target.sourceIdentifier,
        regionCode: regionCode,
        regionName: "測試地區",
        observationTime: observationTime ?? Int(instant("2026-09-25T07:21:00Z")
            .timeIntervalSince1970),
        stationName: "station",
        weather: "晴",
        weatherCode: 100,
        condition: .clear,
        isNight: false,
        nextDayNightTransitionTime: 0,
        calibratedTimeOffsetMilliseconds: offset,
        temperature: 22,
        humidity: 50,
        rain: 0
    )
}

private func instant(_ string: String) -> Date {
    ISO8601DateFormatter().date(from: string)!
}

private func milliseconds(_ string: String) -> Int64 {
    Int64(instant(string).timeIntervalSince1970 * 1_000)
}

// Explicit Release intervals keep these regressions independent of the DEBUG
// runtime cadence. Every async boundary and clock is controlled by the test.
final class ForecastExpiryRegressionTests: XCTestCase {
    private let target = WidgetLocationTarget.saved(regionCode: "407")
    private let initial = instant("2026-09-25T07:21:00Z")

    func testFreshTransitionsKeepNormalReloadAndBothSafetyEntries() async {
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let plan = await planner(forecast: cached()).plan(for: target, family: family)
            XCTAssertEqual(plan.reloadDate, instant("2026-09-25T07:41:00Z"))
            XCTAssertEqual(plan.states.map(\.date), [
                initial, instant("2026-09-25T07:40:00Z"), instant("2026-09-25T07:51:00Z"),
                instant("2026-09-25T09:10:00Z"),
            ])
            XCTAssertNotNil(plan.forecast(at: initial))
            XCTAssertNotNil(plan.forecast(at: instant("2026-09-25T07:40:00Z")))
            XCTAssertNil(plan.forecast(at: instant("2026-09-25T09:10:00Z")))
        }
    }

    func testExpiryAfterRequestedReloadStillSuppliesSafetyEntry() async {
        let plan = await planner(forecast: cached(publication: "2026-09-25T07:20:00Z"))
            .plan(for: target, family: .systemLarge)
        XCTAssertEqual(plan.reloadDate, instant("2026-09-25T07:41:00Z"))
        XCTAssertTrue(plan.states.contains { $0.date == instant("2026-09-25T07:50:00Z") })
        XCTAssertNotNil(plan.forecast(at: instant("2026-09-25T07:50:00Z")))
        XCTAssertTrue(plan.states.contains { $0.date == instant("2026-09-25T09:20:00Z") })
        XCTAssertNil(plan.forecast(at: instant("2026-09-25T09:20:00Z")))
    }

    func testDelayedWidgetKitReloadSelectsExpiryStateAndPreservesCurrentWeather() async throws {
        let plan = await planner(forecast: cached(publication: "2026-09-25T07:20:00Z"))
            .plan(for: target, family: .systemMedium)
        // Simulate WidgetKit keeping this timeline past reload eligibility.
        let delayed = instant("2026-09-25T09:20:30Z")
        let selected = try XCTUnwrap(plan.states.last { $0.date <= delayed })
        XCTAssertEqual(selected.date, instant("2026-09-25T09:20:00Z"))
        XCTAssertNil(plan.forecast(at: selected.date))
        XCTAssertNil(plan.forecast(at: delayed))
        XCTAssertEqual(plan.snapshot?.temperature, 22)
        XCTAssertTrue(selected.isStale)
    }

    func testNearExpiryUsesFiveMinuteFloorInsteadOfImmediateRetry() async {
        let plan = await planner(forecast: cached(publication: "2026-09-25T05:22:00Z"))
            .plan(for: target, family: .systemMedium)
        XCTAssertEqual(plan.reloadDate, instant("2026-09-25T07:26:00Z"))
        XCTAssertTrue(plan.states.contains { $0.date == instant("2026-09-25T07:22:00Z") })
        XCTAssertNil(plan.forecast(at: instant("2026-09-25T07:22:00Z")))
    }

    func testMissingAndExpiredForecastKeepNormalCadenceAndCurrentWeather() async {
        for forecast in [nil, cached(publication: "2026-09-25T05:20:00Z")] {
            let plan = await planner(forecast: forecast).plan(for: target, family: .systemMedium)
            XCTAssertEqual(plan.reloadDate, instant("2026-09-25T07:41:00Z"))
            XCTAssertNil(plan.forecast)
            XCTAssertEqual(plan.snapshot?.stationName, "station")
        }
    }

    func testSmallKeepsNormalTimelineAndNeverRequestsForecast() async {
        let state = ForecastPlannerState(current: currentSnapshot(target: target), forecast: cached())
        let plan = await DPIPWidgetTimelinePlanner(
            staleAfter: 30 * 60, refreshInterval: 20 * 60,
            loadSnapshot: { state.loadCurrent($0) },
            refreshSaved: { _ in .failed }, refreshCurrent: { .failed },
            loadForecast: { state.loadForecast($0, $1, $2) },
            refreshForecast: { await state.refreshForecast($0, $1) },
            now: { self.initial }
        ).plan(for: target, family: .systemSmall)
        XCTAssertEqual(plan.reloadDate, instant("2026-09-25T07:41:00Z"))
        XCTAssertEqual(plan.states, CurrentWeatherWidgetTimeline.states(
            snapshot: plan.snapshot, deviceNow: initial, staleAfter: 30 * 60
        ))
        XCTAssertNil(plan.forecast)
        XCTAssertEqual(state.forecastRefreshCount, 0)
    }

    func testDebugCadenceIsNotLengthenedByReleaseFloor() {
        XCTAssertEqual(ForecastWidgetExpiry.requestedReloadDate(
            now: initial, normalReloadDate: initial.addingTimeInterval(60),
            expiry: initial.addingTimeInterval(30)
        ), initial.addingTimeInterval(60))
    }

    func testMidnightRolloverPreservesForecastPastReceiptHour() async {
        let now = instant("2026-09-25T15:50:00Z") // 23:50 Taipei
        let forecast = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T15:40:00Z"),
            receivedAt: milliseconds("2026-09-25T15:50:00Z"),
            times: ["00:00", "01:00"]
        )
        let plan = await planner(forecast: forecast, now: now)
            .plan(for: target, family: .systemLarge)
        XCTAssertEqual(plan.reloadDate, instant("2026-09-25T16:10:00Z"))
        XCTAssertNotNil(plan.forecast(at: now))
        XCTAssertTrue(plan.states.contains { $0.date == instant("2026-09-25T16:10:00Z") })
        XCTAssertNotNil(plan.forecast(at: instant("2026-09-25T16:00:00Z")))
        XCTAssertNil(plan.forecast(at: instant("2026-09-25T17:40:00Z")))
        let entry = makeEntry(plan: plan, date: now)
        XCTAssertEqual(entry.upcomingForecastPoints(for: .systemLarge).map(\.time),
                       ["00:00", "01:00"])
    }

    func testPositiveAndNegativeClockOffsetsShiftBoundariesAndPreserveReloadCadence() async {
        for offset in [-300_000, 300_000] {
            let seconds = Double(offset) / 1_000
            let deviceNow = initial.addingTimeInterval(-seconds)
            let forecast = forecastSnapshot(
                updateTime: milliseconds("2026-09-25T07:10:00Z"),
                receivedAt: Int64(deviceNow.timeIntervalSince1970 * 1_000),
                times: ["16:00", "17:00"]
            )
            let plan = await planner(forecast: forecast, now: deviceNow, offset: offset)
                .plan(for: target, family: .systemMedium)
            let expiry = instant("2026-09-25T09:10:00Z").addingTimeInterval(-seconds)
            XCTAssertEqual(plan.reloadDate, deviceNow.addingTimeInterval(20 * 60))
            XCTAssertTrue(plan.states.contains { $0.date == expiry })
            XCTAssertNotNil(plan.forecast(at: expiry.addingTimeInterval(-1)))
            XCTAssertNil(plan.forecast(at: expiry))
            XCTAssertEqual(makeEntry(plan: plan, date: deviceNow)
                .upcomingForecastPoints(for: .systemMedium).map(\.time), ["16:00", "17:00"])
        }
    }

    func testSoftBoundaryCoincidingWithCurrentStaleStateIsNotDuplicated() async {
        let now = instant("2026-09-25T07:21:00Z")
        let forecast = cached(publication: "2026-09-25T07:21:00Z")
        let plan = await planner(forecast: forecast, now: now)
            .plan(for: target, family: .systemLarge)
        let expiry = instant("2026-09-25T07:51:00Z")
        XCTAssertEqual(plan.states.filter { $0.date == expiry }.count, 1)
        XCTAssertTrue(plan.states.last!.isStale)
        XCTAssertNotNil(plan.forecast(at: expiry))
        XCTAssertEqual(makeEntry(plan: plan, date: expiry).forecastFreshness, .stale)
    }

    func testForecastTimeoutAndHTTPFailureKeepCacheUntilExpiryThenSuccessfulRefreshRestoresIt() async throws {
        for error: Error in [URLError(.timedOut), ForecastClientError.httpStatus(503)] {
            let clock = TestWallClock(milliseconds: milliseconds("2026-09-25T07:21:00Z"))
            let state = ForecastPlannerState(current: currentSnapshot(target: target), forecast: cached())
            let service = ForecastWidgetRefreshService(
                fetch: { _ in throw error },
                loadCurrent: { state.loadCurrent($0) }, savedIsResolved: { _ in true },
                write: { snapshot, _ in state.forecast = snapshot; return true },
                now: { clock.now() }
            )
            let failedPlanner = DPIPWidgetTimelinePlanner(
                staleAfter: 30 * 60, refreshInterval: 20 * 60,
                loadSnapshot: { state.loadCurrent($0) },
                refreshSaved: { _ in .failed }, refreshCurrent: { .failed },
                loadForecast: { state.loadForecast($0, $1, $2) },
                refreshForecast: { await service.refresh(target: $0, regionCode: $1) },
                now: { clock.now() }
            )
            let before = await failedPlanner.plan(for: target, family: .systemMedium)
            XCTAssertEqual(before.forecast?.updateTime, cached().updateTime)
            clock.set(milliseconds: milliseconds("2026-09-25T09:10:00Z"))
            let after = await failedPlanner.plan(for: target, family: .systemMedium)
            XCTAssertNil(after.forecast)
            XCTAssertEqual(after.snapshot?.temperature, 22)
            XCTAssertEqual(after.reloadDate, instant("2026-09-25T09:30:00Z"))

            let dto = try refreshedDTO(publication: "2026-09-25T09:05:00Z", times: ["18:00", "19:00"])
            let success = ForecastWidgetRefreshService(
                fetch: { _ in dto },
                loadCurrent: { state.loadCurrent($0) }, savedIsResolved: { _ in true },
                write: { snapshot, _ in state.forecast = snapshot; return true },
                now: { clock.now() }
            )
            await success.refresh(target: target, regionCode: "407")
            let restored = await failedPlanner.plan(for: target, family: .systemMedium)
            XCTAssertEqual(restored.forecast?.updateTime, dto.updateTime)
            XCTAssertEqual(makeEntry(plan: restored, date: clock.now())
                .upcomingForecastPoints(for: .systemMedium).map(\.time), ["18:00", "19:00"])
        }
    }

    func testExpiredPublicationIsRejectedWithoutOverwritingCache() async throws {
        for offset in [-300_000, 0, 300_000] {
            let state = ForecastPlannerState(
                current: currentSnapshot(target: target, offset: offset), forecast: cached()
            )
            let dto = try refreshedDTO(publication: "2026-09-25T05:21:00Z")
            let service = ForecastWidgetRefreshService(
                fetch: { _ in dto },
                loadCurrent: { state.loadCurrent($0) }, savedIsResolved: { _ in true },
                write: { snapshot, _ in state.forecast = snapshot; return true },
                now: { self.initial.addingTimeInterval(-Double(offset) / 1_000) }
            )
            await service.refresh(target: target, regionCode: "407")
            XCTAssertEqual(state.forecast?.updateTime, cached().updateTime)
        }
    }

    func testSamePublicationReceivedAcrossHourCannotResurrectExpiredCache() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let first = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:45:00Z"),
            receivedAt: milliseconds("2026-09-25T07:59:00Z"), times: ["16:00", "17:00"]
        )
        XCTAssertTrue(try store.write(first, for: target))
        let repeated = forecastSnapshot(
            updateTime: first.updateTime, receivedAt: milliseconds("2026-09-25T08:01:00Z"),
            times: ["16:00", "17:00"]
        )
        XCTAssertFalse(try store.write(repeated, for: target))
        XCTAssertEqual(store.load(for: target, regionCode: "407",
                                  at: instant("2026-09-25T07:59:30Z"))?.receivedAt, first.receivedAt)
        XCTAssertEqual(store.load(for: target, regionCode: "407",
                                  at: instant("2026-09-25T08:30:00Z"))?.receivedAt, first.receivedAt)
        XCTAssertNil(store.load(for: target, regionCode: "407",
                                at: instant("2026-09-25T09:45:00Z")))
        let newer = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T08:00:00Z"),
            receivedAt: repeated.receivedAt, times: ["17:00"]
        )
        XCTAssertTrue(try store.write(newer, for: target))
        XCTAssertEqual(store.load(for: target, regionCode: "407",
                                  at: instant("2026-09-25T08:01:00Z"))?.updateTime, newer.updateTime)
    }

    func testMissingAndInvalidDiskCacheKeepCurrentWithoutForecast() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let current = currentSnapshot(target: target)
        let planner = DPIPWidgetTimelinePlanner(
            staleAfter: 30 * 60, refreshInterval: 20 * 60,
            loadSnapshot: { _ in current },
            refreshSaved: { _ in .failed }, refreshCurrent: { .failed },
            loadForecast: { store.load(for: $0, regionCode: $1, at: $2) },
            now: { self.initial }
        )
        let missing = await planner.plan(for: target, family: .systemLarge)
        XCTAssertNil(missing.forecast)
        XCTAssertEqual(missing.snapshot?.temperature, 22)
        let url = try XCTUnwrap(store.snapshotURL(for: target))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try Data(#"{"schemaVersion":1,"points":[]}"#.utf8).write(to: url)
        let invalid = await planner.plan(for: target, family: .systemLarge)
        XCTAssertNil(invalid.forecast)
        XCTAssertEqual(invalid.snapshot?.temperature, 22)
    }

    func testLocationChangeDuringForecastAwaitRechecksPlannerSnapshotAndCache() async throws {
        let currentTarget = WidgetLocationTarget.currentLocation
        let state = ForecastPlannerState(current: currentSnapshot(target: currentTarget))
        let dto = try refreshedDTO(publication: "2026-09-25T07:10:00Z")
        let gate = AsyncOperationGate()
        let fetchStarted = expectation(description: "Forecast fetch started")
        let service = ForecastWidgetRefreshService(
            fetch: { _ in
                fetchStarted.fulfill()
                await gate.wait()
                return dto
            },
            loadCurrent: { state.loadCurrent($0) }, savedIsResolved: { _ in true },
            write: { snapshot, _ in state.forecast = snapshot; return true },
            now: { self.initial }
        )
        let planner = DPIPWidgetTimelinePlanner(
            staleAfter: 30 * 60, refreshInterval: 20 * 60,
            loadSnapshot: { state.loadCurrent($0) },
            refreshSaved: { _ in .failed }, refreshCurrent: { .failed },
            loadForecast: { state.loadForecast($0, $1, $2) },
            refreshForecast: { await service.refresh(target: $0, regionCode: $1) },
            now: { self.initial }
        )
        let task = Task { await planner.plan(for: currentTarget, family: .systemLarge) }
        await fulfillment(of: [fetchStarted], timeout: 5)
        state.current = currentSnapshot(target: currentTarget, regionCode: "242")
        // Release even after expectation timeout; open also covers a late waiter.
        await gate.open()
        let plan = await task.value
        XCTAssertEqual(plan.snapshot?.regionCode, "242")
        XCTAssertNil(state.forecast)
        XCTAssertNil(plan.forecast)
    }

    func testDisplayRejectsNoUpcomingExpiredAndWrongLocationForecasts() {
        let forecasts = [
            cached(times: ["13:00", "14:00"]),
            cached(publication: "2026-09-25T05:20:00Z"),
            forecastSnapshot(sourceIdentifier: "region:242", regionCode: "242"),
        ]
        for forecast in forecasts {
            let entry = DPIPWidgetEntry(date: initial, snapshot: currentSnapshot(target: target),
                                        isStale: false, isNight: false, forecast: forecast)
            for family: WidgetFamily in [.systemMedium, .systemLarge, .systemSmall] {
                XCTAssertTrue(entry.upcomingForecastPoints(for: family).isEmpty)
            }
        }
    }

    func testTransitionEntriesUseOwnDatesAndKeepAutomaticRefresh() async throws {
        let publication = instant("2026-09-25T11:26:00Z")
        let soft = instant("2026-09-25T11:56:00Z")
        let hard = instant("2026-09-25T13:26:00Z")
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            for target in [target, .currentLocation] {
                for offset in [-300_000, 0, 300_000] {
                    let correction = Double(offset) / 1_000
                    let now = instant("2026-09-25T11:29:00Z").addingTimeInterval(-correction)
                    let current = currentSnapshot(target: target, offset: offset,
                        observationTime: Int(publication.timeIntervalSince1970))
                    let forecast = forecastSnapshot(sourceIdentifier: target.sourceIdentifier!,
                        updateTime: milliseconds("2026-09-25T11:26:00Z"),
                        receivedAt: Int64(now.timeIntervalSince1970 * 1_000),
                        times: ["20:00", "21:00", "22:00"])
                    let state = ForecastPlannerState(current: current, forecast: forecast)
                    let currentCalls = ForecastCallCounter()
                    let planner = DPIPWidgetTimelinePlanner(staleAfter: 30 * 60,
                        refreshInterval: 20 * 60, loadSnapshot: { state.loadCurrent($0) },
                        refreshSaved: { _ in currentCalls.increment(); return .failed },
                        refreshCurrent: { currentCalls.increment(); return .failed },
                        loadForecast: { state.loadForecast($0, $1, $2) },
                        refreshForecast: { await state.refreshForecast($0, $1) }, now: { now })
                    let plan = await planner.plan(for: target, family: family)
                    XCTAssertEqual(currentCalls.count, 1)
                    XCTAssertEqual(state.forecastRefreshCount, 1)
                    XCTAssertEqual(plan.reloadDate, now.addingTimeInterval(20 * 60))
                    XCTAssertEqual(plan.states.map(\.date), Array(Set(plan.states.map(\.date))).sorted())
                    for (date, expected) in [(now, ForecastWidgetExpiry.Freshness.fresh),
                        (soft.addingTimeInterval(-correction), .stale),
                        (hard.addingTimeInterval(-correction), .expired)] {
                        let scheduled = try XCTUnwrap(plan.states.first { $0.date == date })
                        let entry = DPIPWidgetEntry(date: scheduled.date, snapshot: plan.snapshot,
                            isStale: scheduled.isStale, isNight: scheduled.isNight,
                            forecast: plan.forecast, locationTarget: target)
                        XCTAssertEqual(entry.forecastFreshness, expected)
                        XCTAssertEqual(entry.upcomingForecastPoints(for: family).isEmpty, expected == .expired)
                        XCTAssertEqual(entry.forecastRefreshIdentifier(for: family) != nil, expected != .fresh)
                        XCTAssertNil(entry.forecastRefreshIdentifier(for: .systemSmall))
                        XCTAssertTrue(entry.upcomingForecastPoints(for: .systemSmall).isEmpty)
                    }
                }
            }
        }
    }

    func testSamePublicationRefreshKeepsStaleCacheBytesUntilHardExpiry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let first = cached(times: ["17:00", "18:00"])
        XCTAssertTrue(try store.write(first, for: target))
        let bytes = try Data(contentsOf: XCTUnwrap(store.snapshotURL(for: target)))
        let clock = TestWallClock(milliseconds: milliseconds("2026-09-25T07:40:00Z"))
        let current = currentSnapshot(target: target)
        let dto = try refreshedDTO(publication: "2026-09-25T07:10:00Z")
        let service = ForecastWidgetRefreshService(fetch: { _ in dto },
            loadCurrent: { _ in current }, savedIsResolved: { _ in true },
            write: { try store.write($0, for: $1) }, now: { clock.now() })
        for date in ["2026-09-25T07:40:00Z", "2026-09-25T09:09:59Z", "2026-09-25T09:10:00Z"] {
            clock.set(milliseconds: milliseconds(date))
            await service.refresh(target: target, regionCode: "407")
            XCTAssertEqual(try Data(contentsOf: XCTUnwrap(store.snapshotURL(for: target))), bytes)
            let loaded = store.load(for: target, regionCode: "407", at: clock.now())
            XCTAssertEqual(loaded != nil, date != "2026-09-25T09:10:00Z")
            if let loaded {
                XCTAssertEqual(loaded.receivedAt, first.receivedAt)
                XCTAssertEqual(ForecastWidgetExpiry.freshness(of: loaded, at: clock.now()), .stale)
            }
        }
    }

    func testNewPublicationReplacesStaleCacheAndRestoresFreshTimeline() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let first = cached()
        XCTAssertTrue(try store.write(first, for: target))
        let now = instant("2026-09-25T07:50:00Z")
        XCTAssertEqual(ForecastWidgetExpiry.freshness(of: first, at: now), .stale)
        let current = currentSnapshot(target: target)
        let dto = try refreshedDTO(publication: "2026-09-25T07:49:00Z")
        let service = ForecastWidgetRefreshService(fetch: { _ in dto },
            loadCurrent: { _ in current }, savedIsResolved: { _ in true },
            write: { try store.write($0, for: $1) }, now: { now })
        let planner = DPIPWidgetTimelinePlanner(staleAfter: 30 * 60, refreshInterval: 20 * 60,
            loadSnapshot: { _ in current }, refreshSaved: { _ in .failed },
            refreshCurrent: { .failed },
            loadForecast: { store.load(for: $0, regionCode: $1, at: $2) },
            refreshForecast: { await service.refresh(target: $0, regionCode: $1) }, now: { now })
        let plan = await planner.plan(for: target, family: .systemMedium)
        let loaded = try XCTUnwrap(plan.forecast)
        XCTAssertEqual(loaded.updateTime, dto.updateTime)
        XCTAssertFalse(try store.write(first, for: target))
        XCTAssertEqual(ForecastWidgetExpiry.freshness(of: loaded, at: now), .fresh)
        XCTAssertTrue(plan.states.contains { $0.date == instant("2026-09-25T08:19:00Z") })
        XCTAssertTrue(plan.states.contains { $0.date == instant("2026-09-25T09:49:00Z") })
        let entry = DPIPWidgetEntry(date: now, snapshot: current, isStale: false,
            isNight: false, forecast: loaded, locationTarget: target)
        XCTAssertNil(entry.forecastRefreshIdentifier(for: .systemMedium))
    }

    func testStaleForecastWithoutDisplayableHoursOffersUnavailableRefresh() {
        let forecast = cached(times: ["13:00", "14:00"])
        let entry = DPIPWidgetEntry(date: instant("2026-09-25T07:40:00Z"),
            snapshot: currentSnapshot(target: target), isStale: true, isNight: false,
            forecast: forecast, locationTarget: target)
        XCTAssertEqual(entry.forecastFreshness, .stale)
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            XCTAssertTrue(entry.upcomingForecastPoints(for: family).isEmpty)
            XCTAssertEqual(entry.forecastRefreshIdentifier(for: family), target.sourceIdentifier)
        }
    }

    private func cached(publication: String = "2026-09-25T07:10:00Z",
                        times: [String] = ["16:00", "17:00"]) -> ForecastWidgetSnapshot {
        forecastSnapshot(updateTime: milliseconds(publication),
                         receivedAt: Int64(initial.timeIntervalSince1970 * 1_000), times: times)
    }

    private func planner(forecast: ForecastWidgetSnapshot?, now: Date? = nil,
                         offset: Int = 0) -> DPIPWidgetTimelinePlanner {
        let date = now ?? initial
        let current = currentSnapshot(target: target, offset: offset)
        return DPIPWidgetTimelinePlanner(
            staleAfter: 30 * 60, refreshInterval: 20 * 60,
            loadSnapshot: { _ in current },
            refreshSaved: { _ in .failed }, refreshCurrent: { .failed },
            loadForecast: { target, region, date in
                guard let forecast, forecast.sourceIdentifier == target.sourceIdentifier,
                      forecast.regionCode == region,
                      ForecastWidgetExpiry.isUsable(forecast, at: date,
                          calibratedTimeOffsetMilliseconds: offset) else { return nil }
                return forecast
            },
            now: { date }
        )
    }

    private func makeEntry(plan: DPIPWidgetTimelinePlan, date: Date) -> DPIPWidgetEntry {
        DPIPWidgetEntry(date: date, snapshot: plan.snapshot, isStale: false, isNight: false,
                        forecast: plan.forecast(at: date))
    }

    private func refreshedDTO(publication: String, times: [String] = ["16:00", "17:00"]) throws -> ForecastRemoteDTO {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: forecastJSON(times: times)
        ) as? [String: Any])
        json["updateTime"] = milliseconds(publication)
        return try JSONDecoder().decode(ForecastRemoteDTO.self,
                                         from: JSONSerialization.data(withJSONObject: json))
    }
}

@MainActor
final class ForecastUnavailablePresentationTests: XCTestCase {
    private let date = instant("2026-09-25T07:21:00Z")
    private let locales = ["en", "zh-Hant", "zh-Hans", "ja", "ko"]

    func testMediumAndLargeUnavailableSectionFitsAllLocalesAndLargestText() throws {
        let current = currentSnapshot(target: .saved(regionCode: "407"))
        let entry = DPIPWidgetEntry(date: date, snapshot: current, isStale: false, isNight: false)
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            for locale in locales {
                for size: DynamicTypeSize in [.large, .accessibility5] {
                    let section = HourlyForecastSection(
                        entry: entry, family: family, calibratedDate: date,
                        isCurrentlyNight: false, nextTransitionTime: 0,
                        localizationBundle: Bundle(for: Self.self)
                    )
                    .environment(\.locale, Locale(identifier: locale))
                    .environment(\.dynamicTypeSize, size)
                    let host = UIHostingController(rootView: section)
                    let fitting = host.sizeThatFits(in: CGSize(width: 300, height: 1_000))
                    XCTAssertGreaterThan(fitting.height, 10, "Missing unavailable text: \(locale)")
                    if #available(iOS 17.0, *) {
                        XCTAssertEqual(fitting.height, 44, "Preserve the refresh button's touch target")
                    } else {
                        XCTAssertLessThanOrEqual(fitting.height, 34, "Unavailable state must remain compact")
                    }
                    XCTAssertLessThanOrEqual(fitting.width, 300)
                }
            }
        }
    }

    func testUnavailableStringsExistInEverySupportedLocale() throws {
        let expected = [
            "en": ["Hourly forecast unavailable", "No forecast"],
            "zh-Hant": ["每小時預報暫無資料", "暫無預報"],
            "zh-Hans": ["暂无逐小时预报", "暂无预报"],
            "ja": ["時間別予報は利用できません", "予報なし"],
            "ko": ["시간별 예보를 이용할 수 없습니다", "예보 없음"],
        ]
        let bundle = Bundle(for: Self.self)
        for locale in locales {
            let path = try XCTUnwrap(bundle.path(forResource: locale, ofType: "lproj"))
            let localized = try XCTUnwrap(Bundle(path: path))
            for (index, key) in ["widget.hourly_forecast_unavailable", "widget.forecast_unavailable"].enumerated() {
                XCTAssertEqual(localized.localizedString(forKey: key, value: nil, table: nil),
                               expected[locale]![index])
            }
        }
    }

    func testSmallForecastSectionStaysEmpty() {
        let entry = DPIPWidgetEntry(
            date: date, snapshot: currentSnapshot(target: .saved(regionCode: "407")),
            isStale: false, isNight: false
        )
        let host = UIHostingController(rootView: HourlyForecastSection(
            entry: entry, family: .systemSmall, calibratedDate: date,
            isCurrentlyNight: false, nextTransitionTime: 0
        ))
        XCTAssertEqual(host.sizeThatFits(in: CGSize(width: 300, height: 1_000)).height, 0)
    }

    func testUnavailableAndRestoredWidgetsRenderInLightDarkAndLargerText() throws {
        let current = currentSnapshot(target: .saved(regionCode: "407"))
        let available = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"), times: ["16:00", "17:00"]
        )
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            for scheme: ColorScheme in [.light, .dark] {
                for size: DynamicTypeSize in [.large, .accessibility5] {
                    for forecast in [nil, available] {
                        let entry = DPIPWidgetEntry(
                            date: date, snapshot: current, isStale: false, isNight: false,
                            forecast: forecast
                        )
                        let contentSize = CGSize(width: 338, height: family == .systemMedium ? 158 : 354)
                        let widget = family == .systemMedium
                            ? AnyView(MediumCurrentWeatherView(entry: entry, localizationBundle: Bundle(for: Self.self)))
                            : AnyView(LargeCurrentWeatherView(entry: entry, localizationBundle: Bundle(for: Self.self)))
                        let view = widget
                            .environment(\.locale, Locale(identifier: "zh-Hant"))
                            .environment(\.dynamicTypeSize, size)
                            .environment(\.colorScheme, scheme)
                            .frame(width: contentSize.width, height: contentSize.height, alignment: .topLeading)
                            .padding(16)
                            .background(scheme == .dark ? Color.black : Color.white)
                        let host = UIHostingController(rootView: view)
                        if #available(iOS 16.4, *) {
                            host.safeAreaRegions = []
                        }
                        host.view.frame = CGRect(origin: .zero, size: CGSize(
                            width: contentSize.width + 32, height: contentSize.height + 32
                        ))
                        host.view.backgroundColor = .clear
                        host.view.setNeedsLayout()
                        host.view.layoutIfNeeded()
                        let image = UIGraphicsImageRenderer(size: host.view.bounds.size).image { _ in
                            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
                        }
                        XCTAssertNotNil(image.cgImage)
                        let name = "\(family)-\(scheme)-\(size)-\(forecast == nil ? "unavailable" : "forecast")"
                        let attachment = XCTAttachment(image: image)
                        attachment.name = name
                        attachment.lifetime = .keepAlways
                        add(attachment)
                    }
                }
            }
        }
    }

    func testAccessibilityForecastRowFitsFullTimeNegativeTemperatureAndProbability() throws {
        for size: DynamicTypeSize in [.accessibility1, .accessibility3, .accessibility5] {
            for probability: Int? in [nil, 0, 100] {
                let point = try XCTUnwrap(ForecastWidgetPoint(
                    time: "16:00", temperature: -20, weather: "雷雨", weatherCode: 319, pop: probability
                ))
                let row = AccessibleForecastPointView(point: point, isNight: false)
                    .environment(\.dynamicTypeSize, size)
                    // With an unconstrained ideal width, no parent frame can
                    // mask truncation of the time or either numeric value.
                    .fixedSize(horizontal: true, vertical: true)
                let host = UIHostingController(rootView: row)
                if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
                let fitting = host.sizeThatFits(in: CGSize(width: 300, height: 1_000))
                XCTAssertLessThanOrEqual(fitting.width, 300,
                    "Forecast row clips at \(size), probability=\(String(describing: probability))")
            }
        }
    }

    func testAccessibilityContentFitsWithoutVerticalCompression() throws {
        // Measure the ideal height, before the fixed widget frame can hide
        // overflow. Include four hours and full observations, unlike the
        // minimal render fixture, to exercise both forecast and detail rows.
        let current = CurrentWeatherWidgetSnapshot(
            schemaVersion: 7, sourceIdentifier: "current-location", regionCode: "407",
            regionName: "臺中市西屯區", observationTime: Int(date.timeIntervalSince1970),
            stationName: "臺中氣象觀測站", weather: "雷雨", weatherCode: 319,
            condition: .thunderstorm, isNight: false,
            nextDayNightTransitionTime: Int(date.addingTimeInterval(3_600).timeIntervalSince1970),
            calibratedTimeOffsetMilliseconds: 0, temperature: 32, humidity: 100,
            rain: 123.4, windDirection: "NE", windSpeed: 12.3, apparentTemperature: 38
        )
        let available = try XCTUnwrap(ForecastWidgetSnapshot(
            sourceIdentifier: "current-location", regionCode: "407",
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"),
            points: ["16:00", "17:00", "18:00", "19:00"].map {
                ForecastWidgetPoint(time: $0, temperature: -20, weather: "晴", weatherCode: 100, pop: 100)!
            }
        ))
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            for locale in locales {
                for size: DynamicTypeSize in [.accessibility1, .accessibility3, .accessibility5] {
                    for forecast in [nil, available] {
                        let entry = DPIPWidgetEntry(date: date, snapshot: current,
                                                   isStale: false, isNight: false, forecast: forecast)
                        let widget = family == .systemMedium
                            ? AnyView(MediumCurrentWeatherView(entry: entry, localizationBundle: Bundle(for: Self.self)))
                            : AnyView(LargeCurrentWeatherView(entry: entry, localizationBundle: Bundle(for: Self.self)))
                        let view = widget
                            .environment(\.locale, Locale(identifier: locale))
                            .environment(\.dynamicTypeSize, size)
                            .fixedSize(horizontal: false, vertical: true)
                        let host = UIHostingController(rootView: view)
                        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
                        let fitting = host.sizeThatFits(in: CGSize(width: 300, height: 1_000))
                        let limit: CGFloat = family == .systemMedium ? 158 : 354
                        XCTAssertGreaterThan(fitting.height, 50)
                        XCTAssertLessThanOrEqual(fitting.height, limit,
                            "Content clips: \(family) \(locale) \(size) forecast=\(forecast != nil)")
                        XCTAssertLessThanOrEqual(fitting.width, 300)
                        if size == .accessibility5, ["en", "zh-Hant"].contains(locale) {
                            let render = UIHostingController(rootView: view
                                .frame(width: 300, height: limit, alignment: .topLeading)
                                .padding(16).background(Color.white)
                                .environment(\.colorScheme, .light))
                            if #available(iOS 16.4, *) { render.safeAreaRegions = [] }
                            render.view.frame = CGRect(x: 0, y: 0, width: 332, height: limit + 32)
                            render.view.setNeedsLayout()
                            render.view.layoutIfNeeded()
                            let image = UIGraphicsImageRenderer(size: render.view.bounds.size).image { _ in
                                render.view.drawHierarchy(in: render.view.bounds, afterScreenUpdates: true)
                            }
                            let attachment = XCTAttachment(image: image)
                            attachment.name = "full-observations-\(family)-\(locale)-AX5-\(forecast == nil ? "unavailable" : "forecast")"
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        }
                    }
                }
            }
        }
    }
}

final class ForecastRefreshIntentTests: XCTestCase {
    private let date = instant("2026-09-25T07:21:00Z")

    func testCurrentLocationDoesNotRequireASavedCatalog() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Interactive widgets require iOS 17") }
        let intent = RefreshForecastIntent(locationIdentifier: "current-location")
        XCTAssertEqual(try RefreshForecastIntent.validatedTarget(
            identifier: intent.locationIdentifier, catalog: nil
        ), .currentLocation)
        _ = try await intent.perform()
        XCTAssertFalse(RefreshForecastIntent.openAppWhenRun)
        XCTAssertFalse(RefreshForecastIntent.isDiscoverable)
    }

    func testSavedLocationsRetainIndependentConfiguredIdentifiers() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Interactive widgets require iOS 17") }
        let catalog = try makeCatalog()
        for code in ["407", "433", "407", "433"] {
            let target = WidgetLocationTarget.saved(regionCode: code)
            // A missing cache must not change which configured location is used.
            let entry = DPIPWidgetEntry(date: date, snapshot: nil,
                                        isStale: true, isNight: false, locationTarget: target)
            for family: WidgetFamily in [.systemMedium, .systemLarge] {
                let identifier = try XCTUnwrap(entry.forecastRefreshIdentifier(for: family))
                let intent = RefreshForecastIntent(locationIdentifier: identifier)
                XCTAssertEqual(intent.locationIdentifier, "region:" + code)
                XCTAssertEqual(try RefreshForecastIntent.validatedTarget(
                    identifier: intent.locationIdentifier, catalog: catalog
                ), target)
                _ = try intent.requestRefresh(catalog: catalog)
                XCTAssertEqual(entry.widgetURL.absoluteString,
                               "dpip:///home?widgetLocation=region%3A" + code)
            }
        }
    }

    func testInvalidAndDefaultIdentifiersFailClosed() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Interactive widgets require iOS 17") }
        for identifier in ["", "407", "region:４０７", "region:407/../433", "region:407&other=433", "current-location "] {
            let intent = RefreshForecastIntent(locationIdentifier: identifier)
            XCTAssertThrowsError(try intent.requestRefresh(catalog: makeCatalog())) {
                XCTAssertEqual($0 as? RefreshForecastIntent.ValidationError, .invalidIdentifier)
            }
        }
        XCTAssertThrowsError(try RefreshForecastIntent().requestRefresh(catalog: nil))
    }

    func testDeletedLocationCannotFallBackToAnotherSavedLocation() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Interactive widgets require iOS 17") }
        let intent = RefreshForecastIntent(locationIdentifier: "region:433")
        XCTAssertThrowsError(try intent.requestRefresh(catalog: makeCatalog(codes: ["407"]))) {
            XCTAssertEqual($0 as? RefreshForecastIntent.ValidationError, .locationUnavailable)
        }
    }

    func testMissingCatalogRejectsSavedLocation() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Interactive widgets require iOS 17") }
        XCTAssertThrowsError(try RefreshForecastIntent(locationIdentifier: "region:407")
            .requestRefresh(catalog: nil)) {
            XCTAssertEqual($0 as? RefreshForecastIntent.ValidationError, .locationUnavailable)
        }
    }

    func testUnavailableMediumAndLargeOfferConfiguredActionButSmallDoesNot() {
        let target = WidgetLocationTarget.saved(regionCode: "433")
        let entry = DPIPWidgetEntry(date: date,
                                    snapshot: currentSnapshot(target: target, regionCode: "433"),
                                    isStale: false, isNight: false, locationTarget: target)
        XCTAssertEqual(entry.forecastRefreshIdentifier(for: .systemMedium), "region:433")
        XCTAssertEqual(entry.forecastRefreshIdentifier(for: .systemLarge), "region:433")
        XCTAssertNil(entry.forecastRefreshIdentifier(for: .systemSmall))
        XCTAssertNil(entry.forecastRefreshIdentifier(for: .systemExtraLarge))
        XCTAssertEqual(entry.snapshot?.temperature, 22)
    }

    func testValidForecastHidesActionAndExpiryRestoresItWithoutLosingCurrentWeather() {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let forecast = forecastSnapshot(updateTime: milliseconds("2026-09-25T07:10:00Z"),
                                        receivedAt: milliseconds("2026-09-25T07:21:00Z"),
                                        times: ["16:00", "17:00"])
        for family: WidgetFamily in [.systemMedium, .systemLarge] {
            let available = DPIPWidgetEntry(date: date, snapshot: currentSnapshot(target: target),
                                            isStale: false, isNight: false, forecast: forecast,
                                            locationTarget: target)
            XCTAssertFalse(available.upcomingForecastPoints(for: family).isEmpty)
            XCTAssertNil(available.forecastRefreshIdentifier(for: family))
            let expired = DPIPWidgetEntry(date: instant("2026-09-25T09:10:00Z"),
                                          snapshot: available.snapshot, isStale: true,
                                          isNight: false, forecast: forecast, locationTarget: target)
            XCTAssertTrue(expired.upcomingForecastPoints(for: family).isEmpty)
            XCTAssertEqual(expired.forecastRefreshIdentifier(for: family), "region:407")
            XCTAssertEqual(expired.snapshot?.temperature, available.snapshot?.temperature)
            XCTAssertEqual(expired.widgetURL, available.widgetURL)
        }
    }

    func testActionDoesNotUseGalleryOrCachedWeatherForLocation() {
        let sample = DPIPWidgetGalleryPreview.sample(at: date)
        let target = WidgetLocationTarget.saved(regionCode: "433")
        let unavailable = DPIPWidgetEntry(date: date, snapshot: sample.snapshot,
                                          isStale: false, isNight: false, locationTarget: target)
        XCTAssertEqual(unavailable.forecastRefreshIdentifier(for: .systemMedium), "region:433")
        let preview = DPIPWidgetEntry(date: date, snapshot: sample.snapshot,
                                      isStale: false, isNight: false, forecast: sample.forecast,
                                      locationTarget: target)
        XCTAssertFalse(preview.upcomingForecastPoints(for: .systemMedium).isEmpty)
        XCTAssertNil(preview.forecastRefreshIdentifier(for: .systemMedium))
        let invalid = DPIPWidgetEntry(date: date, snapshot: sample.snapshot,
                                      isStale: false, isNight: false,
                                      locationTarget: .invalid(identifier: "region:bad"))
        XCTAssertNil(invalid.forecastRefreshIdentifier(for: .systemMedium))
    }

    func testRepeatedRequestsLeaveCachedPublicationAndReceiptBytesUntouched() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Interactive widgets require iOS 17") }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ForecastWidgetSnapshotStore(containerURL: directory)
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let original = forecastSnapshot(updateTime: milliseconds("2026-09-25T07:10:00Z"),
                                        receivedAt: milliseconds("2026-09-25T07:21:00Z"),
                                        times: ["16:00", "17:00"])
        XCTAssertTrue(try store.write(original, for: target))
        let url = try XCTUnwrap(store.snapshotURL(for: target))
        let bytes = try Data(contentsOf: url)
        for _ in 0..<10 {
            _ = try RefreshForecastIntent(locationIdentifier: "region:407")
                .requestRefresh(catalog: makeCatalog())
        }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        for publication in [original.updateTime, original.updateTime - 60_000] {
            XCTAssertFalse(try store.write(forecastSnapshot(
                updateTime: publication, receivedAt: original.receivedAt + 60_000,
                times: ["16:00", "17:00"]
            ), for: target))
        }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        XCTAssertNotNil(store.load(for: target, regionCode: "407", at: instant("2026-09-25T07:40:00Z")))
        XCTAssertNil(store.load(for: target, regionCode: "407", at: instant("2026-09-25T09:10:00Z")))
        let newer = forecastSnapshot(updateTime: milliseconds("2026-09-25T07:35:00Z"),
                                     receivedAt: milliseconds("2026-09-25T07:40:00Z"),
                                     times: ["16:00", "17:00"])
        XCTAssertTrue(try store.write(newer, for: target))
        XCTAssertEqual(store.load(for: target, regionCode: "407",
                                  at: instant("2026-09-25T07:40:00Z"))?.updateTime, newer.updateTime)
    }

    func testRefreshAccessibilityStringsExistInEveryWidgetLocale() throws {
        let bundle = Bundle(for: Self.self)
        let expectedLabels = ["en": "Refresh forecast", "zh-Hant": "重新整理預報",
                              "zh-Hans": "刷新预报", "ja": "予報を更新", "ko": "예보 새로 고침"]
        let outdated = ["en": "Forecast may be outdated", "zh-Hant": "預報資料較舊",
                        "zh-Hans": "预报数据较旧", "ja": "予報データが古くなっています",
                        "ko": "예보 데이터가 오래되었습니다"]
        for (locale, label) in expectedLabels {
            let localized = try XCTUnwrap(Bundle(path: XCTUnwrap(bundle.path(forResource: locale, ofType: "lproj"))))
            XCTAssertEqual(localized.localizedString(forKey: "widget.refresh_forecast", value: nil, table: nil), label)
            XCTAssertEqual(localized.localizedString(forKey: "widget.forecast_outdated", value: nil, table: nil), outdated[locale])
            let hint = localized.localizedString(forKey: "widget.refresh_forecast_hint", value: nil, table: nil)
            XCTAssertFalse(hint.isEmpty)
            XCTAssertNotEqual(hint, "widget.refresh_forecast_hint")
        }
    }

    private func makeCatalog(codes: [String] = ["407", "433"]) throws -> WidgetLocationCatalog {
        let locations: [[String: Any]] = codes.map {
            ["regionCode": $0, "displayName": "Test", "administrativeAreaName": "Test",
             "latitude": 24.16, "longitude": 120.64]
        }
        return try XCTUnwrap(WidgetLocationCatalog.decode(JSONSerialization.data(
            withJSONObject: ["schemaVersion": 1, "locations": locations]
        )))
    }
}
