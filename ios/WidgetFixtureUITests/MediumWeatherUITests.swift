import XCTest

final class MediumWeatherUITests: XCTestCase {
    // Independent expectations for the catalog and regional clock formatting.
    // The fixture uses the production catalog; these literals are test oracles.
    private enum Language: String {
        case en, traditionalChinese = "zh-Hant", simplifiedChinese = "zh-Hans", ja, ko

        var expected: (locale: String, warning: String, refresh: String) {
            switch self {
            case .en: ("en_US", "Forecast may be outdated", "Refresh forecast")
            case .traditionalChinese: ("zh_Hant_TW", "預報資料較舊", "重新整理預報")
            case .simplifiedChinese: ("zh_Hans_CN", "预报数据较旧", "刷新预报")
            case .ja: ("ja_JP", "予報データが古くなっています", "予報を更新")
            case .ko: ("ko_KR", "예보 데이터가 오래되었습니다", "예보 새로 고침")
            }
        }

        func timeLabel(utcHour: Int) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: expected.locale)
            formatter.timeZone = TimeZone(identifier: "Asia/Taipei")!
            formatter.timeStyle = .short
            // 2026-09-25 00:00 UTC; observation 06:21 UTC, entry 07:21 UTC.
            return formatter.string(from: Date(timeIntervalSince1970: 1_790_294_400 + Double(utcHour * 3600 + 21 * 60)))
        }
    }

    private enum Forecast: String {
        case stale, fresh, expired, unavailable
    }

    private enum TextSize: String {
        case normal, larger, accessibility
    }

    private enum Location: String {
        case short, long, compact

        var label: String {
            switch self {
            case .short: "Taichung Xitun"
            case .compact: "Xitun"
            case .long: "Taichung City Xitun District Shuinan Central Park"
            }
        }
    }

    private let tolerance: CGFloat = 0.5

    func testEnglishStaleMediumHeader() {
        assertStale(.en, warningRole: .image, screenshot: "medium-stale-english")
    }

    func testCompactLocationEnglishStaleMediumUsesWarningText() {
        assertStale(.en, location: .compact, warningRole: .staticText, screenshot: "medium-stale-english-text")
    }

    func testTraditionalChineseStaleMediumHeader() {
        assertStale(.traditionalChinese, warningRole: .staticText, screenshot: "medium-stale-zh-Hant")
    }

    func testSimplifiedChineseStaleMediumHeader() {
        assertStale(.simplifiedChinese, warningRole: .staticText)
    }

    func testJapaneseStaleMediumHeader() {
        assertStale(.ja, warningRole: .image)
    }

    func testKoreanStaleMediumHeader() {
        assertStale(.ko, warningRole: .image)
    }

    func testLargerRegularTextWithLongLocationUsesWarningImage() {
        assertStale(.en, size: .larger, location: .long, warningRole: .image, screenshot: "medium-stale-larger")
    }

    func testAccessibilityTextWithLongLocationUsesWarningImageAndCombinedForecast() {
        assertStale(.en, size: .accessibility, location: .long, warningRole: .image, screenshot: "medium-stale-accessibility")
    }

    func testFreshForecastKeepsForecastWithoutWarningOrRefresh() {
        assertNonStale(.fresh, screenshot: "medium-fresh-english")
    }

    func testExpiredForecastShowsUnavailableStatusAndRefreshWithoutWarning() {
        assertNonStale(.expired)
    }

    func testUnavailableForecastShowsStatusAndRefreshWithoutWarning() {
        assertNonStale(.unavailable)
    }

    private func launch(_ forecast: Forecast, language: Language, size: TextSize, location: Location) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "DPIP_FIXTURE_FORECAST": forecast.rawValue,
            "DPIP_FIXTURE_LANGUAGE": language.rawValue,
            "DPIP_FIXTURE_TEXT_SIZE": size.rawValue,
            "DPIP_FIXTURE_LOCATION": location.rawValue,
        ]
        app.launch()
        return app
    }

    private func assertStale(
        _ language: Language, size: TextSize = .normal, location: Location = .short,
        warningRole: XCUIElement.ElementType, screenshot: String? = nil
    ) {
        let app = launch(.stale, language: language, size: size, location: location)
        capture(screenshot)
        guard let layout = assertCurrentWeather(app, language: language, location: location) else { return }

        let warningLabel = language.expected.warning
        if let warning = requireOne(elements(app, label: warningLabel), "Stale warning '\(warningLabel)'") {
            XCTAssertEqual(warning.elementType, warningRole, "Wrong stale warning representation")
            assertInside(warning.frame, layout.bounds, "Stale warning")
            XCTAssertLessThanOrEqual(warning.frame.maxX, layout.time.minX + tolerance, "Warning must precede observation time")
            XCTAssertGreaterThan(min(warning.frame.maxY, layout.time.maxY),
                                 max(warning.frame.minY, layout.time.minY),
                                 "Warning and observation time must share a row")
        }
        assertRefresh(app, label: language.expected.refresh, region: layout.forecast)
        _ = assertForecast(app, size: size, region: layout.forecast)
    }

    private func assertNonStale(_ forecast: Forecast, screenshot: String? = nil) {
        let app = launch(forecast, language: .en, size: .normal, location: .short)
        capture(screenshot)
        guard let layout = assertCurrentWeather(app, language: .en, location: .short) else { return }

        if forecast == .fresh {
            guard assertForecast(app, size: .normal, region: layout.forecast) else { return }
            XCTAssertEqual(app.buttons.count, 0, "Fresh forecast must not offer refresh")
        } else {
            guard let status = requireOne(texts(app, label: "Hourly forecast unavailable"), "Forecast unavailable status"),
                  assertRefresh(app, label: Language.en.expected.refresh, region: layout.forecast) else { return }
            assertInside(status.frame, layout.forecast, "Forecast unavailable status")
            for label in ["16:00", "22°", "20%"] {
                XCTAssertEqual(elements(app, label: label).count, 0, "Unexpected expired or missing forecast value: \(label)")
            }
        }
        // Positive current-weather and state-specific content must exist first.
        XCTAssertEqual(elements(app, label: Language.en.expected.warning).count, 0, "Non-stale forecast exposed a stale warning")
    }

    private func assertCurrentWeather(
        _ app: XCUIApplication, language: Language, location: Location
    ) -> (bounds: CGRect, time: CGRect, forecast: CGRect)? {
        guard texts(app, label: location.label).firstMatch.waitForExistence(timeout: 10) else {
            XCTFail("Missing fixture location '\(location.label)'; widget accessibility content did not load")
            return nil
        }

        let boundary = app.descendants(matching: .any).matching(identifier: "widget-presentation-boundary")
        let timeLabel = language.timeLabel(utcHour: 6)
        guard let marker = requireOne(boundary, "Independent presentation boundary"),
              let time = requireOne(elements(app, label: timeLabel), "Observation time '\(timeLabel)'"),
              let temperature = requireOne(texts(app, label: "32°"), "Current temperature") else { return nil }

        let bounds = marker.frame
        XCTAssertEqual(bounds.width, 338, accuracy: tolerance)
        XCTAssertEqual(bounds.height, 158, accuracy: tolerance)
        XCTAssertEqual(time.elementType, .staticText)
        XCTAssertEqual(elements(app, label: language.timeLabel(utcHour: 7)).count, 0, "Entry time must not replace observation time")
        assertInside(time.frame, bounds, "Observation time")
        assertInside(temperature.frame, bounds, "Current temperature")

        let content = bounds.insetBy(dx: 16, dy: 0)
        let forecast = CGRect(x: content.minX, y: temperature.frame.maxY,
                              width: content.width, height: content.maxY - temperature.frame.maxY)
        return (bounds, time.frame, forecast)
    }

    @discardableResult
    private func assertRefresh(_ app: XCUIApplication, label: String, region: CGRect) -> Bool {
        guard let refresh = requireOne(elements(app, label: label), "Refresh '\(label)'") else { return false }
        XCTAssertEqual(refresh.elementType, .button)
        XCTAssertEqual(app.buttons.count, 1)
        XCTAssertEqual(refresh.frame.width, 44, accuracy: tolerance)
        XCTAssertEqual(refresh.frame.height, 44, accuracy: tolerance)
        assertInside(refresh.frame, region, "Refresh button")
        return true
    }

    private func assertForecast(_ app: XCUIApplication, size: TextSize, region: CGRect) -> Bool {
        if size == .accessibility {
            let rows = app.descendants(matching: .any).matching(NSPredicate(
                format: "label CONTAINS %@ AND label CONTAINS %@ AND label CONTAINS %@", "16:00", "22°", "20%"
            ))
            guard let row = requireOne(rows, "Accessible forecast row with time, temperature and precipitation") else { return false }
            assertInside(row.frame, region, "Accessible forecast row")
        } else {
            guard let time = requireOne(texts(app, label: "16:00"), "Forecast time"),
                  let temperature = requireOne(texts(app, label: "22°"), "Forecast temperature"),
                  let precipitation = requireOne(texts(app, label: "20%"), "Forecast precipitation") else { return false }
            assertInside(time.frame, region, "Forecast time")
            assertInside(temperature.frame, region, "Forecast temperature")
            // The regular fixture may clip the bottom of the precipitation row.
            // Check its semantic position and association without certifying glyph visibility.
            XCTAssertTrue(region.intersects(precipitation.frame), "Forecast precipitation must intersect the forecast region")
            XCTAssertGreaterThanOrEqual(precipitation.frame.minX, region.minX - tolerance)
            XCTAssertLessThanOrEqual(precipitation.frame.maxX, region.maxX + tolerance)
            XCTAssertGreaterThanOrEqual(precipitation.frame.minY, temperature.frame.maxY - tolerance)
            XCTAssertEqual(temperature.frame.midX, time.frame.midX, accuracy: tolerance)
            XCTAssertEqual(precipitation.frame.midX, time.frame.midX, accuracy: tolerance)
        }
        return true
    }

    private func assertInside(_ frame: CGRect, _ bounds: CGRect, _ name: String) {
        XCTAssertFalse(frame.isEmpty, "\(name) must have a nonempty frame")
        XCTAssertTrue(bounds.insetBy(dx: -tolerance, dy: -tolerance).contains(frame),
                      "\(name) outside fixed presentation region: \(frame) vs \(bounds)")
    }

    private func elements(_ app: XCUIApplication, label: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label))
    }

    private func texts(_ app: XCUIApplication, label: String) -> XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "label == %@", label))
    }

    private func requireOne(_ query: XCUIElementQuery, _ name: String) -> XCUIElement? {
        let count = query.count
        XCTAssertEqual(count, 1, "\(name) must appear exactly once")
        return count == 1 ? query.element : nil
    }

    private func capture(_ name: String?) {
        guard let name else { return }
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
