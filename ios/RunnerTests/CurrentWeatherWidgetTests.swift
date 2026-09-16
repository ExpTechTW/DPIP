import Foundation
import XCTest

final class CurrentWeatherWidgetSnapshotTests: XCTestCase {
    func testDecodesSchemaVersionThreeSnapshot() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 3,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "晴",
              "weatherCode": 100,
              "condition": "clear",
              "isNight": true,
              "nextDayNightTransitionTime": 1789562700,
              "temperature": 28.5,
              "humidity": null,
              "rain": 0.0
            }
            """
        )

        XCTAssertEqual(snapshot.schemaVersion, 3)
        XCTAssertEqual(snapshot.regionCode, "660")
        XCTAssertEqual(snapshot.regionName, "西屯區")
        XCTAssertEqual(snapshot.observationTime, 1_789_567_200)
        XCTAssertEqual(snapshot.stationName, "西屯")
        XCTAssertEqual(snapshot.weather, "晴")
        XCTAssertEqual(snapshot.weatherCode, 100)
        XCTAssertEqual(snapshot.condition, .clear)
        XCTAssertTrue(snapshot.isNight)
        XCTAssertEqual(snapshot.nextDayNightTransitionTime, 1_789_562_700)
        XCTAssertEqual(snapshot.temperature, 28.5)
        XCTAssertNil(snapshot.humidity)
        XCTAssertEqual(snapshot.rain, 0)
    }

    func testDecodesOlderSnapshotWithDayNightDefaults() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 2,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "晴",
              "weatherCode": 100,
              "condition": "clear",
              "temperature": null,
              "humidity": null,
              "rain": null
            }
            """
        )

        XCTAssertFalse(snapshot.isNight)
        XCTAssertEqual(snapshot.nextDayNightTransitionTime, 0)
        XCTAssertNil(snapshot.temperature)
        XCTAssertNil(snapshot.humidity)
        XCTAssertNil(snapshot.rain)
    }

    func testUnknownConditionDecodesAsUnknown() throws {
        let snapshot = try decode(
            """
            {
              "schemaVersion": 3,
              "regionCode": "660",
              "regionName": "西屯區",
              "observationTime": 1789567200,
              "stationName": "西屯",
              "weather": "未知",
              "weatherCode": 999,
              "condition": "future-condition",
              "isNight": false,
              "nextDayNightTransitionTime": 0,
              "temperature": null,
              "humidity": null,
              "rain": null
            }
            """
        )

        XCTAssertEqual(snapshot.condition, .unknown)
    }

    private func decode(_ json: String) throws -> CurrentWeatherWidgetSnapshot {
        try JSONDecoder().decode(
            CurrentWeatherWidgetSnapshot.self,
            from: Data(json.utf8)
        )
    }
}

final class CurrentWeatherWidgetConditionTests: XCTestCase {
    func testClearAndCloudyUseDayNightSymbols() {
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.clear.systemImageName(isNight: false),
            "sun.max.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.clear.systemImageName(isNight: true),
            "moon.stars.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.cloudy.systemImageName(isNight: false),
            "cloud.sun.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.cloudy.systemImageName(isNight: true),
            "cloud.moon.fill"
        )
    }

    func testRainSymbolDoesNotDependOnDayNight() {
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.rain.systemImageName(isNight: false),
            "cloud.rain.fill"
        )
        XCTAssertEqual(
            CurrentWeatherWidgetCondition.rain.systemImageName(isNight: true),
            "cloud.rain.fill"
        )
    }
}

final class CurrentWeatherWidgetTimelineTests: XCTestCase {
    private let staleAfter: TimeInterval = 30 * 60

    func testDayToNightBeforeStale() {
        let now = date(10_000)
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_200
            ),
            now: now,
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: false),
                state(at: 11_200, isStale: false, isNight: true),
                state(at: 11_800, isStale: true, isNight: true),
            ]
        )
    }

    func testStaleBeforeDayToNightTransition() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 8_800,
                isNight: false,
                transitionTime: 11_200
            ),
            now: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: false),
                state(at: 10_600, isStale: true, isNight: false),
                state(at: 11_200, isStale: true, isNight: true),
            ]
        )
    }

    func testNightToDayTransition() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: true,
                transitionTime: 11_200
            ),
            now: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertTrue(states[0].isNight)
        XCTAssertFalse(states[1].isNight)
        XCTAssertFalse(states[2].isNight)
    }

    func testEqualStaleAndTransitionDatesAreDeduplicatedAndCombined() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_800
            ),
            now: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: false),
                state(at: 11_800, isStale: true, isNight: true),
            ]
        )
    }

    func testPastTransitionAffectsNowWithoutSchedulingPastDate() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 9_999
            ),
            now: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(states.map(\.date), [date(10_000), date(11_800)])
        XCTAssertTrue(states[0].isNight)
        XCTAssertFalse(states[0].isStale)
    }

    func testAlreadyStaleSnapshotIsStaleAtNow() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 8_000,
                isNight: false,
                transitionTime: 0
            ),
            now: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [state(at: 10_000, isStale: true, isNight: false)]
        )
    }

    func testZeroTransitionUsesSnapshotStateWithoutSolarEntry() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: true,
                transitionTime: 0
            ),
            now: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [
                state(at: 10_000, isStale: false, isNight: true),
                state(at: 11_800, isStale: true, isNight: true),
            ]
        )
    }

    func testNoSnapshotProducesOneEmptyState() {
        let states = CurrentWeatherWidgetTimeline.states(
            snapshot: nil,
            now: date(10_000),
            staleAfter: staleAfter
        )

        XCTAssertEqual(
            states,
            [state(at: 10_000, isStale: false, isNight: false)]
        )
    }

    func testSnapshotStateAfterTransitionUsesDateAwareNightValue() {
        let state = CurrentWeatherWidgetTimeline.state(
            snapshot: snapshot(
                observationTime: 10_000,
                isNight: false,
                transitionTime: 11_200
            ),
            at: date(11_201),
            staleAfter: staleAfter
        )

        XCTAssertTrue(state.isNight)
        XCTAssertFalse(state.isStale)
    }

    private func snapshot(
        observationTime: Int,
        isNight: Bool,
        transitionTime: Int
    ) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: 3,
            regionCode: "660",
            regionName: "西屯區",
            observationTime: observationTime,
            stationName: "西屯",
            weather: "晴",
            weatherCode: 100,
            condition: .clear,
            isNight: isNight,
            nextDayNightTransitionTime: transitionTime,
            temperature: 28,
            humidity: 76,
            rain: 0
        )
    }

    private func state(
        at timestamp: TimeInterval,
        isStale: Bool,
        isNight: Bool
    ) -> CurrentWeatherWidgetTimelineState {
        CurrentWeatherWidgetTimelineState(
            date: date(timestamp),
            isStale: isStale,
            isNight: isNight
        )
    }

    private func date(_ timestamp: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timestamp)
    }
}
