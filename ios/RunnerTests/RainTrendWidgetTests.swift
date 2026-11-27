import Foundation
import SwiftUI
import UIKit
import WidgetKit
import XCTest

/// Mirrors `test/features/weather/domain/rain_hour_trend_test.dart`: the
/// widget and the Home sheet must read the same hour the same way.
final class RainHourTrendTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_786_362_699)

    private func rain60(_ leading: [Int]) -> String {
        let values = leading + Array(repeating: 0, count: 60 - leading.count)
        return "[" + values.map(String.init).joined(separator: ",") + "]"
    }

    private func decode(_ json: String) throws -> RainHourTrend {
        try RainHourTrend.decode(Data(json.utf8), now: now)
    }

    private func trend(_ values: [Double]) -> RainHourTrend {
        RainHourTrend(
            startSecond: 60,
            mm: values + Array(repeating: 0, count: 60 - values.count)
        )!
    }

    func testDecodeReadsTheFirstNonEmptySeriesInResponseOrder() throws {
        // "other" sorts first alphabetically; the response lists it second.
        let trend = try decode("""
        {"rainfallWarnings-rkai":[{"start":1786362600,"rain":\(rain60([6, 5, 4]))}],
         "rainfallWarnings-other":[{"start":1,"rain":[]}]}
        """)

        XCTAssertEqual(trend.startSecond, 1_786_362_600)
        XCTAssertEqual(trend.mm.count, 60)
        XCTAssertEqual(Array(trend.mm.prefix(3)), [6, 5, 4])
        XCTAssertTrue(trend.mm.dropFirst(3).allSatisfy { $0 == 0 })
    }

    func testEmptyResponsesAreADryHourFromNow() throws {
        for json in ["{}", #"{"rainfallWarnings-rkai":[]}"#] {
            let trend = try decode(json)

            XCTAssertTrue(trend.isDry, json)
            XCTAssertEqual(trend.mm, Array(repeating: 0, count: 60), json)
            XCTAssertEqual(trend.startSecond, 1_786_362_660, json)
            XCTAssertEqual(trend.summary.grade, .none, json)
        }
    }

    func testDecodeSkipsEmptySeriesBeforeTheRealOne() throws {
        let trend = try decode("""
        {"empty":[],"real":[{"start":10,"rain":\(rain60([1]))}]}
        """)

        XCTAssertEqual(trend.startSecond, 10)
    }

    func testMalformedSeriesFailInsteadOfReadingAsDry() {
        for json in [
            #"{"s":[{"start":"now","rain":\#(rain60([1]))}]}"#,
            #"{"s":[{"start":10,"rain":[1,2]}]}"#,
            #"{"s":[42]}"#,
            #"{"s":[{"start":10,"rain":\#(rain60([-1]))}]}"#,
            #"{"s":[{"start":10,"rain":["1"\#(String(repeating: ",0", count: 59))]}]}"#,
            "[]",
            "not json",
        ] {
            XCTAssertThrowsError(try decode(json), json)
        }
    }

    func testSummaryGradesThePeakAndFindsWhereTheRainStops() {
        let dry = trend([]).summary
        XCTAssertEqual(dry, .init(grade: .none, sustained: false, stopInMinutes: nil))

        XCTAssertEqual(trend([0, 4.9, 0, 0, 0, 2.5]).summary.grade, .scattered)
        XCTAssertNil(trend([0, 4.9, 0, 0, 0, 2.5]).summary.stopInMinutes)
        XCTAssertEqual(trend([5]).summary.grade, .light)

        let stopping = trend(Array(repeating: 6, count: 21)).summary
        XCTAssertEqual(stopping, .init(grade: .light, sustained: false, stopInMinutes: 21))

        let sustained = trend(Array(repeating: 0, count: 45) + [6]).summary
        XCTAssertEqual(sustained, .init(grade: .light, sustained: true, stopInMinutes: nil))

        XCTAssertEqual(trend([15]).summary.grade, .heavy)
        let heavyStopping = trend(Array(repeating: 20, count: 10)).summary
        XCTAssertEqual(heavyStopping, .init(grade: .heavy, sustained: false, stopInMinutes: 10))
        let heavySustained = trend(Array(repeating: 20, count: 60)).summary
        XCTAssertEqual(heavySustained, .init(grade: .heavy, sustained: true, stopInMinutes: nil))
    }

    // MARK: Minutes still ahead

    func testSummaryReadsOnlyTheMinutesStillAhead() {
        // Light rain in minutes 0 through 19, as in the UI fixture.
        let light = trend(Array(repeating: 6, count: 20))
        func reading(_ elapsed: Int) -> RainHourTrend.Summary {
            light.summary(elapsedMinutes: elapsed)
        }

        // At the start the widget reads the hour as the app does.
        XCTAssertEqual(reading(0), light.summary)
        XCTAssertEqual(reading(0), .init(grade: .light, sustained: false, stopInMinutes: 20))
        // Mid-rain, the stop counts from the moment read.
        XCTAssertEqual(reading(1), .init(grade: .light, sustained: false, stopInMinutes: 19))
        XCTAssertEqual(reading(10), .init(grade: .light, sustained: false, stopInMinutes: 10))
        XCTAssertEqual(reading(19), .init(grade: .light, sustained: false, stopInMinutes: 1))
        // The rain has ended: the rest of the hour is dry.
        XCTAssertEqual(reading(20), .init(grade: .none, sustained: false, stopInMinutes: nil))
        XCTAssertEqual(reading(25).grade, .none)
        // The hour is entirely past.
        XCTAssertEqual(reading(60).grade, .none)
        XCTAssertEqual(reading(90).grade, .none)
        // An origin still ahead puts the stop that much further off.
        XCTAssertEqual(reading(-2).stopInMinutes, 22)
    }

    func testRemainingMinutesSetTheGradeButNotTheSustainedWindow() {
        // Heavy for five minutes, then light through minute 19.
        let easing = trend(Array(repeating: 20, count: 5) + Array(repeating: 6, count: 15))
        XCTAssertEqual(easing.summary(elapsedMinutes: 0).grade, .heavy)
        XCTAssertEqual(
            easing.summary(elapsedMinutes: 5),
            .init(grade: .light, sustained: false, stopInMinutes: 15)
        )
        let showersLeft = trend(Array(repeating: 6, count: 10) + [0, 2])
        XCTAssertEqual(showersLeft.summary(elapsedMinutes: 10).grade, .scattered)

        // Rain to the end of the forecast is still sustained halfway in, not
        // "stops in 30 minutes" where the forecast merely runs out.
        let wholeHour = trend(Array(repeating: 6, count: 60))
        XCTAssertEqual(
            wholeHour.summary(elapsedMinutes: 30),
            .init(grade: .light, sustained: true, stopInMinutes: nil)
        )
    }

    func testCalibratedInstantsCountWholeMinutesSinceTheOrigin() {
        let light = trend(Array(repeating: 6, count: 20))
        let origin = light.startDate

        XCTAssertEqual(light.elapsedMinutes(at: origin.addingTimeInterval(59)), 0)
        XCTAssertEqual(light.elapsedMinutes(at: origin.addingTimeInterval(10 * 60 + 59)), 10)
        XCTAssertEqual(light.elapsedMinutes(at: origin.addingTimeInterval(-30)), 0)
        XCTAssertEqual(light.summary(at: origin.addingTimeInterval(10 * 60 + 30)).stopInMinutes, 10)
        XCTAssertFalse(light.isDry(at: origin.addingTimeInterval(20 * 60 - 1)))
        XCTAssertTrue(light.isDry(at: origin.addingTimeInterval(20 * 60)))
        XCTAssertEqual(light.rainEndDate, origin.addingTimeInterval(20 * 60))
        XCTAssertNil(trend([]).rainEndDate)
    }

    func testClientRequestsTheTownshipAndRejectsAnythingElse() throws {
        XCTAssertEqual(
            try RainTrendClient().makeURL(regionCode: "407").absoluteString,
            "https://exptech.dingbot.tw/api/weather/rainforecast/407"
        )
        for code in ["", "40", "4070", "abc", "../1"] {
            XCTAssertThrowsError(try RainTrendClient().makeURL(regionCode: code), code)
        }
    }

    func testSnapshotRoundTripsThroughJSON() throws {
        let snapshot = RainTrendWidgetSnapshot(
            sourceIdentifier: "region:407", regionCode: "407",
            trend: trend([1, 2, 3])
        )
        let decoded = try JSONDecoder().decode(
            RainTrendWidgetSnapshot.self, from: JSONEncoder().encode(snapshot)
        )
        XCTAssertEqual(decoded, snapshot)
    }
}

final class RainTrendWidgetTests: XCTestCase {
    /// 15:21 Taipei. The trend starts at 15:20.
    private let now = Date(timeIntervalSince1970: 1_790_320_860)
    private let start: Int64 = 1_790_320_800
    private let target = WidgetLocationTarget.saved(regionCode: "407")

    private func current(offset: Int = 0) -> CurrentWeatherWidgetSnapshot {
        CurrentWeatherWidgetSnapshot(
            schemaVersion: 7, sourceIdentifier: "region:407", regionCode: "407",
            regionName: "西屯區", observationTime: Int(start) - 600,
            stationName: "西屯", weather: "雨", weatherCode: 206,
            condition: .rain, isNight: false, nextDayNightTransitionTime: 0,
            calibratedTimeOffsetMilliseconds: offset,
            temperature: 24, humidity: 90, rain: 3
        )
    }

    private func rain(
        _ mm: [Double] = Array(repeating: 6, count: 30) + Array(repeating: 0, count: 30),
        region: String = "407"
    ) -> RainTrendWidgetSnapshot {
        RainTrendWidgetSnapshot(
            sourceIdentifier: "region:\(region)", regionCode: region,
            trend: RainHourTrend(startSecond: start, mm: mm)!
        )
    }

    // MARK: Timeline

    func testChartEntriesStepFiveMinutesAndEndWithTheHour() {
        let plan = WidgetTimelineBuilder(refreshInterval: 30 * 60).plan(
            snapshot: current(), forecast: nil, rain: rain(),
            outcome: .refreshed, deviceNow: now
        )
        let origin = Date(timeIntervalSince1970: TimeInterval(start))
        let expected = [now] + (1...12).map {
            origin.addingTimeInterval(Double($0) * 300)
        }

        XCTAssertEqual(plan.states.map(\.date), expected)
        XCTAssertNotNil(plan.rain(at: origin.addingTimeInterval(55 * 60)))
        XCTAssertNil(plan.rain(at: origin.addingTimeInterval(60 * 60)))
        // Entries are free; the reload cadence does not change.
        XCTAssertEqual(plan.reloadDate, now.addingTimeInterval(30 * 60))
    }

    func testChartEntriesFollowTheCalibratedClock() {
        // The device runs five minutes behind the server.
        let plan = WidgetTimelineBuilder(refreshInterval: 30 * 60).plan(
            snapshot: current(offset: 300_000), forecast: nil, rain: rain(),
            outcome: .refreshed, deviceNow: now.addingTimeInterval(-300)
        )
        let end = Date(timeIntervalSince1970: TimeInterval(start) + 3_600 - 300)

        XCTAssertEqual(plan.states.last?.date, end)
        XCTAssertNotNil(plan.rain(at: end.addingTimeInterval(-1)))
        XCTAssertNil(plan.rain(at: end))
    }

    func testADryHourAddsNoEntries() {
        let plan = WidgetTimelineBuilder(refreshInterval: 30 * 60).plan(
            snapshot: current(), forecast: nil,
            rain: rain(Array(repeating: 0, count: 60)),
            outcome: .refreshed, deviceNow: now
        )

        XCTAssertEqual(plan.states, CurrentWeatherWidgetTimeline.states(
            snapshot: current(), deviceNow: now,
            staleAfter: CurrentWeatherWidgetTimeline.defaultStaleAfter
        ))
    }

    func testPlannerLoadsRainOnlyForMediumAndLarge() async {
        let snapshot = current()
        let cached = rain()
        let planner = DPIPWidgetTimelinePlanner(
            builder: WidgetTimelineBuilder(refreshInterval: 30 * 60),
            loadSnapshot: { _ in snapshot },
            loadRain: { _, region in region == "407" ? cached : nil },
            refresh: { _, _ in .refreshed },
            now: { self.now }
        )

        let small = await planner.plan(for: target, family: .systemSmall)
        let medium = await planner.plan(for: target, family: .systemMedium)

        XCTAssertNil(small.rain)
        XCTAssertEqual(medium.rain, cached)
    }

    // MARK: Entry

    func testChartReplacesTheHourlyRowOnlyWhileRainIsComing() {
        func entry(
            _ rain: RainTrendWidgetSnapshot?, at date: Date? = nil
        ) -> DPIPWidgetEntry {
            DPIPWidgetEntry(
                date: date ?? now, snapshot: current(), isStale: false,
                isNight: false, rain: rain, locationTarget: target
            )
        }

        XCTAssertNotNil(entry(rain()).visibleRainTrend(for: .systemMedium))
        XCTAssertNotNil(entry(rain()).visibleRainTrend(for: .systemLarge))
        XCTAssertNil(entry(rain()).visibleRainTrend(for: .systemSmall))
        XCTAssertNil(entry(nil).visibleRainTrend(for: .systemMedium))
        XCTAssertNil(entry(rain(Array(repeating: 0, count: 60)))
            .visibleRainTrend(for: .systemMedium))
        XCTAssertNil(entry(rain(region: "242")).visibleRainTrend(for: .systemLarge))
        XCTAssertNil(entry(
            rain(), at: Date(timeIntervalSince1970: TimeInterval(start) + 3_600)
        ).visibleRainTrend(for: .systemLarge))
    }

    // MARK: Minutes still ahead

    /// `minutes` after the 15:20 origin.
    private func minute(_ minutes: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(start) + TimeInterval(minutes * 60))
    }

    /// The UI fixture's hour: light rain from 15:20 through 15:39.
    private func stoppingRain() -> RainTrendWidgetSnapshot {
        rain(Array(repeating: 6, count: 20) + Array(repeating: 0, count: 40))
    }

    func testEachEntryReadsTheRainLeftAtItsOwnInstant() throws {
        let bundle = try localization("zh-Hant")
        func line(at date: Date) -> String? {
            let entry = DPIPWidgetEntry(
                date: date, snapshot: current(), isStale: false, isNight: false,
                rain: stoppingRain(), locationTarget: target
            )
            guard let trend = entry.visibleRainTrend(for: .systemMedium) else {
                return nil
            }
            return RainTrendSection.summary(
                of: trend,
                at: CurrentWeatherWidgetTimeCalibration(snapshot: current())
                    .calibratedDate(fromDeviceDate: date),
                bundle: bundle
            )
        }

        // Start: fetched at 15:21.
        XCTAssertEqual(line(at: minute(1)), "預計 19 分鐘後停止下小雨")
        // Mid-rain.
        XCTAssertEqual(line(at: minute(10)), "預計 10 分鐘後停止下小雨")
        // The rain has ended: no chart, the hourly row is back.
        XCTAssertNil(line(at: minute(20)))
        XCTAssertNil(line(at: minute(25)))
        // The hour is entirely past.
        XCTAssertNil(line(at: minute(60)))
        XCTAssertNil(line(at: minute(90)))
    }

    func testRainLeftIsReadOnTheCalibratedClock() {
        func entry(at date: Date, offset: Int) -> DPIPWidgetEntry {
            DPIPWidgetEntry(
                date: date, snapshot: current(offset: offset), isStale: false,
                isNight: false, rain: stoppingRain(), locationTarget: target
            )
        }

        XCTAssertNotNil(entry(at: minute(16), offset: 0).visibleRainTrend(for: .systemMedium))
        // The device runs five minutes behind: its 15:36 is the server's
        // 15:41, after the rain.
        XCTAssertNil(entry(at: minute(16), offset: 300_000).visibleRainTrend(for: .systemMedium))
    }

    func testTheChartLeavesTheMinuteTheRainEnds() {
        // Rain through 15:36, ending at 15:37: between two five-minute steps.
        let plan = WidgetTimelineBuilder(refreshInterval: 30 * 60).plan(
            snapshot: current(), forecast: nil,
            rain: rain(Array(repeating: 6, count: 17) + Array(repeating: 0, count: 43)),
            outcome: .refreshed, deviceNow: now
        )
        func charted(_ date: Date) -> Bool {
            DPIPWidgetEntry(
                date: date, snapshot: current(), isStale: false, isNight: false,
                rain: plan.rain(at: date), locationTarget: target
            ).visibleRainTrend(for: .systemMedium) != nil
        }

        XCTAssertTrue(plan.states.map(\.date).contains(minute(17)))
        XCTAssertTrue(charted(minute(15)))
        XCTAssertFalse(charted(minute(17)))
    }

    func testRainAlreadyBehindAddsNoEntries() {
        let deviceNow = minute(25)
        let plan = WidgetTimelineBuilder(refreshInterval: 30 * 60).plan(
            snapshot: current(), forecast: nil, rain: stoppingRain(),
            outcome: .refreshed, deviceNow: deviceNow
        )

        XCTAssertEqual(plan.states, CurrentWeatherWidgetTimeline.states(
            snapshot: current(), deviceNow: deviceNow,
            staleAfter: CurrentWeatherWidgetTimeline.defaultStaleAfter
        ))
    }

    // MARK: Chart

    func testBarsShiftWithTheMinutesSinceTheOriginAndLeaveTheRestEmpty() {
        let trend = RainHourTrend(
            startSecond: start,
            mm: [50] + Array(repeating: 1, count: 58) + [2]
        )!

        let atStart = RainTrendChart.slots(for: trend, elapsedMinutes: 0)
        XCTAssertEqual(atStart.first, 35, "capped at 35 mm")
        XCTAssertEqual(atStart.last, 2)
        XCTAssertTrue(atStart.allSatisfy { $0 != nil })

        let later = RainTrendChart.slots(for: trend, elapsedMinutes: 25)
        XCTAssertEqual(later.first, 1)
        XCTAssertEqual(later[34], 2)
        XCTAssertTrue(later[35...].allSatisfy { $0 == nil })

        // A fetch newer than its stamp: the first minutes have no forecast.
        let early = RainTrendChart.slots(for: trend, elapsedMinutes: -3)
        XCTAssertTrue(early[..<3].allSatisfy { $0 == nil })
        XCTAssertEqual(early[3], 35)
    }

    // MARK: Compact accessibility

    func testCompactAccessibilityTightensTheChartAsTheHourlyRowIs() {
        let compact = RainTrendSection.layout(for: .systemMedium, compactAccessibility: true)
        let medium = RainTrendSection.layout(for: .systemMedium, compactAccessibility: false)
        let large = RainTrendSection.layout(for: .systemLarge, compactAccessibility: false)

        XCTAssertEqual(RainTrendSection.layout(for: .systemLarge, compactAccessibility: true), compact)
        // The type stops at the default size, as each hourly column's does,
        // and the gaps close as the hourly column's do.
        XCTAssertEqual(compact.maximumTypeSize, .large)
        XCTAssertEqual(compact.spacing, 0)
        XCTAssertLessThan(compact.chartHeight, medium.chartHeight)
        // The title line and the drop give way to the summary.
        XCTAssertFalse(compact.showsTitleLine)
        XCTAssertFalse(compact.showsDrop)

        XCTAssertEqual(medium.maximumTypeSize, .xLarge)
        XCTAssertTrue(medium.showsDrop)
        XCTAssertFalse(medium.showsTitleLine)
        XCTAssertEqual(large.maximumTypeSize, .xxLarge)
        XCTAssertTrue(large.showsTitleLine)
    }

    @MainActor
    func testCompactAccessibilityRendersTheSameShortChartAtTheLargestTextSize() throws {
        let bundle = try localization("en")
        let trend = rain(Array(repeating: 20, count: 60)).trend
        func height(
            _ family: WidgetFamily, compact: Bool, size: DynamicTypeSize = .accessibility5
        ) -> CGFloat {
            UIHostingController(rootView: RainTrendSection(
                trend: trend, calibratedDate: now, family: family,
                localizationBundle: bundle, compactAccessibility: compact
            ).environment(\.dynamicTypeSize, size))
                .sizeThatFits(in: CGSize(width: 306, height: 400)).height
        }

        let compact = height(.systemMedium, compact: true)
        XCTAssertLessThan(compact, height(.systemMedium, compact: false))
        XCTAssertLessThan(compact, height(.systemLarge, compact: false))
        XCTAssertEqual(height(.systemLarge, compact: true), compact, accuracy: 0.5)
        XCTAssertEqual(height(.systemMedium, compact: true, size: .large), compact, accuracy: 0.5)
    }

    // MARK: Strings and rendering

    private let locales = ["en", "zh-Hant", "zh-Hans", "ja", "ko"]

    private func localization(_ locale: String) throws -> Bundle {
        let path = try XCTUnwrap(
            Bundle(for: Self.self).path(forResource: locale, ofType: "lproj")
        )
        return try XCTUnwrap(Bundle(path: path))
    }

    func testTextsMatchTheAppInTraditionalChinese() throws {
        let bundle = try localization("zh-Hant")
        func summary(_ grade: RainHourTrend.Grade, _ stop: Int?) -> String {
            RainTrendSection.summary(
                .init(grade: grade, sustained: stop == nil, stopInMinutes: stop),
                bundle: bundle
            )
        }

        XCTAssertEqual(summary(.scattered, nil), "可能會有零星降雨")
        XCTAssertEqual(summary(.light, nil), "未來 1 小時會有持續小雨")
        XCTAssertEqual(summary(.light, 21), "預計 21 分鐘後停止下小雨")
        XCTAssertEqual(summary(.heavy, nil), "未來 1 小時會有持續大雨")
        XCTAssertEqual(summary(.heavy, 10), "預計 10 分鐘後停止下大雨")
        XCTAssertEqual(
            RainTrendSection.updated(
                Date(timeIntervalSince1970: TimeInterval(start)), bundle: bundle
            ),
            "更新 15:20"
        )
        XCTAssertEqual(RainTrendSection.tickLabel(0, bundle: bundle), "現在")
        XCTAssertEqual(RainTrendSection.tickLabel(30, bundle: bundle), "30分")
    }

    func testEveryWidgetLocaleCarriesTheRainStrings() throws {
        let keys = [
            "widget.rain_trend_title", "widget.rain_trend_scattered",
            "widget.rain_trend_light_sustained", "widget.rain_trend_light_stopping %lld",
            "widget.rain_trend_heavy_sustained", "widget.rain_trend_heavy_stopping %lld",
            "widget.rain_trend_updated %@", "widget.rain_trend_minute %lld",
            "widget.rain_trend_now",
        ]
        for locale in locales {
            let bundle = try localization(locale)
            for key in keys {
                let value = bundle.localizedString(forKey: key, value: nil, table: nil)
                XCTAssertNotEqual(value, key, "\(locale) \(key)")
                XCTAssertFalse(value.isEmpty, "\(locale) \(key)")
            }
        }
    }

    @MainActor
    func testChartRendersInEveryLocaleAppearanceAndFamily() throws {
        let trend = rain().trend
        for locale in locales {
            let bundle = try localization(locale)
            for family: WidgetFamily in [.systemMedium, .systemLarge] {
                for scheme: ColorScheme in [.light, .dark] {
                    let host = UIHostingController(rootView: RainTrendSection(
                        trend: trend, calibratedDate: now, family: family,
                        localizationBundle: bundle
                    ).environment(\.colorScheme, scheme))
                    let size = host.sizeThatFits(in: CGSize(width: 320, height: 400))
                    XCTAssertGreaterThan(size.height, 40, "\(locale) \(family)")
                    XCTAssertLessThan(
                        size.height, family == .systemMedium ? 90 : 140,
                        "\(locale) \(family)"
                    )
                }
            }
        }
    }
}
