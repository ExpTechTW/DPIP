import Foundation
import WidgetKit
import XCTest

final class ForecastRemoteDTOTests: XCTestCase {
    func testDecodesFirstFourUsablePointsInAPIOrderAcrossMidnight() throws {
        let dto = try forecastDTO(
            times: ["bad", "23:00", "00:00", "01:00", "02:00", "03:00"]
        )
        XCTAssertEqual(dto.updateTime, 1_790_336_400_000)
        XCTAssertEqual(dto.points.map(\.time),
                       ["23:00", "00:00", "01:00", "02:00"])
    }

    func testFewerThanFourAndEmptyForecast() throws {
        XCTAssertEqual(try forecastDTO(times: ["12:00"]).points.count, 1)
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
                       ["23:00", "00:00", "01:00", "02:00"])
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
    func testPublicationPlusThirtyMinutesWins() {
        let snapshot = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z")
        )
        XCTAssertEqual(ForecastWidgetExpiry.date(for: snapshot),
                       instant("2026-09-25T07:40:00Z"))
        XCTAssertTrue(ForecastWidgetExpiry.isUsable(
            snapshot, at: instant("2026-09-25T07:39:59Z")))
        XCTAssertFalse(ForecastWidgetExpiry.isUsable(
            snapshot, at: instant("2026-09-25T07:40:00Z")))
    }

    func testNextTaipeiHourWinsAndIgnoresDeviceTimezone() {
        let snapshot = forecastSnapshot(
            updateTime: milliseconds("2026-09-25T07:40:00Z"),
            receivedAt: milliseconds("2026-09-25T07:50:00Z")
        )
        let expected = instant("2026-09-25T08:00:00Z")
        let original = NSTimeZone.default
        defer { NSTimeZone.default = original }
        NSTimeZone.default = TimeZone(identifier: "America/Los_Angeles")!
        XCTAssertEqual(ForecastWidgetExpiry.date(for: snapshot), expected)
        NSTimeZone.default = TimeZone(identifier: "Pacific/Auckland")!
        XCTAssertEqual(ForecastWidgetExpiry.date(for: snapshot), expected)
        XCTAssertFalse(ForecastWidgetExpiry.isUsable(snapshot, at: expected))
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
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        XCTAssertTrue(try store.write(snapshot, for: saved))
        XCTAssertEqual(store.load(for: saved, regionCode: "407", at: date)?
            .points.first?.time, "23:00")
        XCTAssertNil(store.load(for: other, regionCode: "242", at: date))
        XCTAssertNil(store.load(for: saved, regionCode: "242", at: date))
        XCTAssertFalse(try store.write(snapshot, for: other))
        let otherSnapshot = forecastSnapshot(
            sourceIdentifier: "region:242", regionCode: "242",
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        XCTAssertTrue(try store.write(otherSnapshot, for: other))
        XCTAssertNotNil(store.load(for: other, regionCode: "242", at: date))
        XCTAssertNotNil(store.load(for: saved, regionCode: "407", at: date))

        let currentSnapshot = forecastSnapshot(
            sourceIdentifier: "current-location", regionCode: "407",
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
                                at: instant("2026-09-25T07:40:00Z")))
        let url = try XCTUnwrap(store.snapshotURL(for: target))
        try Data("broken".utf8).write(to: url, options: .atomic)
        XCTAssertNil(store.load(for: target, regionCode: "407",
                                at: instant("2026-09-25T07:21:00Z")))
        try Data(repeating: 65, count: 128 * 1024 + 1)
            .write(to: url, options: .atomic)
        XCTAssertNil(store.load(for: target, regionCode: "407",
                                at: instant("2026-09-25T07:21:00Z")))
    }
}

final class ForecastWidgetProviderTests: XCTestCase {
    func testOnlyLargeRefreshesAndSnapshotPathIsCacheOnly() async {
        let target = WidgetLocationTarget.saved(regionCode: "407")
        let state = ForecastPlannerState(current: currentSnapshot(target: target))
        let planner = makePlanner(state: state)
        _ = await planner.plan(for: target, family: .systemSmall)
        _ = await planner.plan(for: target, family: .systemMedium)
        XCTAssertEqual(state.forecastRefreshCount, 0)
        _ = await planner.plan(for: target, family: .systemLarge)
        XCTAssertEqual(state.forecastRefreshCount, 1)
        XCTAssertEqual(state.requestedRegions, ["407"])
        let dependencies = DPIPWidgetProviderDependencies(
            loadSnapshot: { state.loadCurrent($0) },
            timelinePlanner: planner,
            loadForecast: { state.loadForecast($0, $1, $2) }
        )
        _ = dependencies.snapshot(for: target)
        _ = dependencies.forecastSnapshot(
            for: target, currentSnapshot: state.loadCurrent(target),
            at: instant("2026-09-25T07:21:00Z"), family: .systemLarge
        )
        XCTAssertEqual(state.forecastRefreshCount, 1)
    }

    func testForecastFailureKeepsCurrentAndValidCacheFallback() async {
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
        XCTAssertEqual(plan.snapshot?.regionCode, "407")
        XCTAssertNotNil(plan.forecast)
        let expiry = instant("2026-09-25T07:40:00Z")
        XCTAssertEqual(plan.states.count, 3)
        XCTAssertTrue(plan.states.contains { $0.date == expiry })
        XCTAssertNotNil(plan.forecast(at: plan.states[0].date))
        XCTAssertNil(plan.forecast(at: expiry))
        XCTAssertEqual(plan.snapshot?.stationName, "station")
    }

    func testExpiredAndMismatchedCacheNeverAttaches() async {
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
            for: target, family: .systemLarge
        )
        XCTAssertNil(regionMismatch.forecast)
        state.forecast = forecastSnapshot(
            sourceIdentifier: "region:242", regionCode: "242",
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        let sourceMismatch = await makePlanner(state: state).plan(
            for: target, family: .systemLarge
        )
        XCTAssertNil(sourceMismatch.forecast)
        state.forecast = forecastSnapshot(
            sourceIdentifier: "current-location", regionCode: "242",
            updateTime: milliseconds("2026-09-25T07:10:00Z"),
            receivedAt: milliseconds("2026-09-25T07:21:00Z"))
        let latePlanner = makePlanner(
            state: state, now: instant("2026-09-25T07:40:00Z")
        )
        let expired = await latePlanner.plan(for: target,
                                             family: .systemLarge)
        XCTAssertNil(expired.forecast)
    }

    func testLateCurrentLocationResponseForAIsNotWrittenAfterB() async {
        let target = WidgetLocationTarget.currentLocation
        let state = ForecastPlannerState(
            current: currentSnapshot(target: target, regionCode: "407"))
        let gate = AsyncOperationGate()
        let dto = try! forecastDTO(times: ["23:00"])
        let service = ForecastWidgetRefreshService(
            fetch: { _ in await gate.wait(); return dto },
            loadCurrent: { state.loadCurrent($0) },
            savedIsResolved: { _ in true },
            write: { snapshot, _ in state.forecast = snapshot; return true },
            now: { instant("2026-09-25T07:21:00Z") }
        )
        let task = Task { await service.refresh(target: target,
                                                regionCode: "407") }
        while !(await gate.hasStarted) { await Task.yield() }
        state.current = currentSnapshot(target: target, regionCode: "242")
        await gate.open()
        await task.value
        XCTAssertNil(state.forecast)
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
    private var regions: [String] = []

    init(current: CurrentWeatherWidgetSnapshot?,
         forecast: ForecastWidgetSnapshot? = nil) {
        storedCurrent = current
        storedForecast = forecast
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
              ForecastWidgetExpiry.isUsable(forecast, at: date) else {
            return nil
        }
        return forecast
    }

    func refreshForecast(_ target: WidgetLocationTarget,
                         _ regionCode: String) async {
        lock.withLock { regions.append(regionCode) }
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
    receivedAt: Int64 = 1_790_337_060_000
) -> ForecastWidgetSnapshot {
    ForecastWidgetSnapshot(
        sourceIdentifier: sourceIdentifier,
        regionCode: regionCode,
        updateTime: updateTime,
        receivedAt: receivedAt,
        points: ["23:00", "00:00", "01:00", "02:00"].map {
            ForecastWidgetPoint(time: $0, temperature: 22,
                                weather: "晴", weatherCode: 100,
                                pop: 20)!
        }
    )!
}

private func currentSnapshot(target: WidgetLocationTarget,
                             regionCode: String = "407")
    -> CurrentWeatherWidgetSnapshot {
    CurrentWeatherWidgetSnapshot(
        schemaVersion: 7,
        sourceIdentifier: target.sourceIdentifier,
        regionCode: regionCode,
        regionName: "測試地區",
        observationTime: Int(instant("2026-09-25T07:21:00Z")
            .timeIntervalSince1970),
        stationName: "station",
        weather: "晴",
        weatherCode: 100,
        condition: .clear,
        isNight: false,
        nextDayNightTransitionTime: 0,
        calibratedTimeOffsetMilliseconds: 0,
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
