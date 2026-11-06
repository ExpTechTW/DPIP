import XCTest

final class MediumWeatherUITests: XCTestCase {
    // Independent expectations for the catalog and regional clock formatting.
    // The fixture uses the production catalog; these literals are test oracles.
    private enum Language: String, CaseIterable {
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

        var unavailableLabel: String {
            switch self {
            case .en: "Hourly forecast unavailable"
            case .traditionalChinese: "每小時預報暫無資料"
            case .simplifiedChinese: "暂无逐小时预报"
            case .ja: "時間別予報は利用できません"
            case .ko: "시간별 예보를 이용할 수 없습니다"
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
        case short, long, compact, xitun, longChinese

        var label: String {
            switch self {
            case .short: "Taichung Xitun"
            case .compact: "Xitun"
            case .long: "Taichung City Xitun District Shuinan Central Park"
            case .xitun: "西屯"
            case .longChinese: "臺中市西屯區臺灣大道三段"
            }
        }
    }

    private enum Card: String {
        case narrow, wide

        var size: CGSize {
            switch self {
            case .narrow: CGSize(width: 338, height: 158)
            case .wide: CGSize(width: 364, height: 170)
            }
        }
    }

    private let hours = ["16:00", "17:00", "18:00", "19:00", "20:00"]
    private let temperatures = ["22°", "23°", "24°", "25°", "26°"]
    private let probabilities = ["20%", "30%", "40%", "50%", "60%"]
    private let margin: CGFloat = 16
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

    func testWideStaleMediumUsesLocalizedWarningText() {
        for language in Language.allCases {
            XCTContext.runActivity(named: language.rawValue) { _ in
                assertStale(language, location: .xitun, card: .wide, warningRole: .staticText,
                            screenshot: "stale-wide-\(language.rawValue)")
            }
        }
    }

    func testWideAccessibilityStaleMediumUsesLocalizedWarningImage() {
        for language in [Language.ja, .traditionalChinese] {
            XCTContext.runActivity(named: language.rawValue) { _ in
                assertStale(language, size: .accessibility, location: .longChinese, card: .wide,
                            warningRole: .image, screenshot: "stale-wide-ax1-\(language.rawValue)")
            }
        }
    }

    func testNarrowStaleForecastDoesNotIncreaseFreshOverflow() {
        let stale = assertStale(.en, location: .longChinese, warningRole: .image,
                                screenshot: "stale-narrow-long-Chinese")
        let fresh = assertNonStale(.fresh, location: .longChinese, screenshot: "fresh-narrow-long-Chinese")
        guard let stale, let fresh else { return }
        XCTAssertLessThanOrEqual(stale.bottom - stale.cardBottom, max(0, fresh.bottom - fresh.cardBottom) + tolerance,
                                 "Stale forecast must not increase overflow below the narrow card")
    }

    func testTraditionalChineseNonStaleStatesAtRegularAndAccessibilitySizes() {
        for forecast in [Forecast.fresh, .expired, .unavailable] {
            for size in [TextSize.normal, .accessibility] {
                XCTContext.runActivity(named: "\(forecast.rawValue)-\(size.rawValue)") { _ in
                    assertNonStale(forecast, language: .traditionalChinese, size: size, location: .xitun, card: .wide,
                                   screenshot: forecast == .unavailable && size == .normal ? "unavailable-zh-Hant-large" : nil)
                }
            }
        }
    }

    private func launch(
        _ forecast: Forecast, language: Language, size: TextSize, location: Location, card: Card
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "DPIP_FIXTURE_FORECAST": forecast.rawValue,
            "DPIP_FIXTURE_LANGUAGE": language.rawValue,
            "DPIP_FIXTURE_TEXT_SIZE": size.rawValue,
            "DPIP_FIXTURE_LOCATION": location.rawValue,
            "DPIP_FIXTURE_CARD": card.rawValue,
        ]
        app.launch()
        return app
    }

    @discardableResult
    private func assertStale(
        _ language: Language, size: TextSize = .normal, location: Location = .short,
        card: Card = .narrow, warningRole: XCUIElement.ElementType, screenshot: String? = nil
    ) -> (bottom: CGFloat, cardBottom: CGFloat)? {
        let app = launch(.stale, language: language, size: size, location: location, card: card)
        capture(screenshot)
        guard let layout = assertCurrentWeather(app, language: language, location: location, card: card) else { return nil }

        let warningLabel = language.expected.warning
        if let warning = requireOne(elements(app, label: warningLabel), "Stale warning '\(warningLabel)'") {
            let frame = warning.frame
            XCTAssertEqual(warning.elementType, warningRole, "Wrong stale warning representation")
            assertInside(frame, layout.bounds.insetBy(dx: margin, dy: margin), "Stale warning")
            XCTAssertLessThanOrEqual(layout.location.maxX, frame.minX + tolerance, "Location must precede stale warning")
            XCTAssertLessThanOrEqual(frame.maxX, layout.time.minX + tolerance, "Warning must precede observation time")
            XCTAssertGreaterThan(min(frame.maxY, layout.time.maxY), max(frame.minY, layout.time.minY),
                                 "Warning and observation time must share a row")
        }
        let refresh = assertRefresh(app, label: language.expected.refresh, region: layout.forecast)
        guard let forecast = assertForecast(app, size: size, card: card, region: layout.forecast) else { return nil }
        if let refresh {
            XCTAssertLessThanOrEqual(forecast.maxX, refresh.minX + tolerance, "Forecast must not overlap refresh")
        }
        return (forecast.maxY, layout.bounds.maxY)
    }

    @discardableResult
    private func assertNonStale(
        _ forecast: Forecast, language: Language = .en, size: TextSize = .normal,
        location: Location = .short, card: Card = .narrow, screenshot: String? = nil
    ) -> (bottom: CGFloat, cardBottom: CGFloat)? {
        let app = launch(forecast, language: language, size: size, location: location, card: card)
        capture(screenshot)
        guard let layout = assertCurrentWeather(app, language: language, location: location, card: card) else { return nil }

        var forecastFrame: CGRect?
        if forecast == .fresh {
            guard let frame = assertForecast(app, size: size, card: card, region: layout.forecast) else { return nil }
            forecastFrame = frame
            XCTAssertEqual(app.buttons.count, 0, "Fresh forecast must not offer refresh")
        } else {
            guard let status = requireOne(texts(app, label: language.unavailableLabel), "Forecast unavailable status"),
                  assertRefresh(app, label: language.expected.refresh, region: layout.forecast) != nil else { return nil }
            assertInside(status.frame, layout.forecast, "Forecast unavailable status")
            let unexpectedForecast = app.descendants(matching: .any).matching(NSCompoundPredicate(
                orPredicateWithSubpredicates: (hours + temperatures + probabilities).map {
                    NSPredicate(format: "label CONTAINS %@", $0)
                }
            ))
            XCTAssertEqual(unexpectedForecast.count, 0, "Expired or missing forecasts must not show hourly values")
        }
        // Positive current-weather and state-specific content must exist first.
        XCTAssertEqual(elements(app, label: language.expected.warning).count, 0, "Non-stale forecast exposed a stale warning")
        return forecastFrame.map { ($0.maxY, layout.bounds.maxY) }
    }

    private func assertCurrentWeather(
        _ app: XCUIApplication, language: Language, location: Location, card: Card
    ) -> (bounds: CGRect, location: CGRect, time: CGRect, forecast: CGRect)? {
        guard texts(app, label: location.label).firstMatch.waitForExistence(timeout: 10) else {
            XCTFail("Missing fixture location '\(location.label)'; widget accessibility content did not load")
            return nil
        }

        let boundary = app.descendants(matching: .any).matching(identifier: "widget-presentation-boundary")
        let timeLabel = language.timeLabel(utcHour: 6)
        guard let marker = requireOne(boundary, "Independent presentation boundary"),
              let locationElement = requireOne(texts(app, label: location.label), "Location"),
              let time = requireOne(elements(app, label: timeLabel), "Observation time '\(timeLabel)'"),
              let temperature = requireOne(texts(app, label: "32°"), "Current temperature") else { return nil }

        let bounds = marker.frame
        XCTAssertEqual(bounds.width, card.size.width, accuracy: tolerance)
        XCTAssertEqual(bounds.height, card.size.height, accuracy: tolerance)
        XCTAssertEqual(time.elementType, .staticText)
        XCTAssertEqual(elements(app, label: language.timeLabel(utcHour: 7)).count, 0, "Entry time must not replace observation time")
        let header = bounds.insetBy(dx: margin, dy: margin)
        let timeFrame = time.frame
        let locationFrame = locationElement.frame
        let temperatureFrame = temperature.frame
        assertInside(timeFrame, header, "Observation time")
        assertInside(locationFrame, header, "Location")
        assertInside(temperatureFrame, bounds, "Current temperature")

        let forecastTop = max(temperatureFrame.maxY, timeFrame.maxY)
        let forecast = CGRect(x: header.minX, y: forecastTop,
                              width: header.width, height: bounds.maxY - forecastTop)
        return (bounds, locationFrame, timeFrame, forecast)
    }

    private func assertRefresh(_ app: XCUIApplication, label: String, region: CGRect) -> CGRect? {
        guard let refresh = requireOne(elements(app, label: label), "Refresh '\(label)'") else { return nil }
        XCTAssertEqual(refresh.elementType, .button, "Refresh must expose the Button role")
        XCTAssertEqual(app.buttons.count, 1)
        XCTAssertTrue(refresh.isEnabled, "Refresh button must be enabled")
        let frame = refresh.frame
        XCTAssertEqual(frame.width, 44, accuracy: tolerance)
        XCTAssertEqual(frame.height, 44, accuracy: tolerance)
        assertInside(frame, region, "Refresh button")
        return frame
    }

    private func assertForecast(_ app: XCUIApplication, size: TextSize, card: Card, region: CGRect) -> CGRect? {
        if size == .accessibility {
            let rows = app.descendants(matching: .any).matching(NSPredicate(
                format: "label CONTAINS %@ AND label CONTAINS %@ AND label CONTAINS %@",
                hours[0], temperatures[0], probabilities[0]
            ))
            guard let row = requireOne(rows, "Accessible forecast row with time, temperature and precipitation") else { return nil }
            let frame = row.frame
            assertInside(frame, region, "Accessible forecast row")
            return frame
        }

        var forecast = CGRect.null
        var hourFrames: [CGRect] = []
        for (index, hour) in hours.enumerated() {
            guard let time = requireOne(texts(app, label: hour), "Forecast time \(hour)"),
                  let temperature = requireOne(texts(app, label: temperatures[index]), "Forecast temperature at \(hour)"),
                  let precipitation = requireOne(texts(app, label: probabilities[index]), "Forecast precipitation at \(hour)") else { return nil }
            let timeFrame = time.frame
            let temperatureFrame = temperature.frame
            let precipitationFrame = precipitation.frame
            assertInside(timeFrame, region, "Forecast time \(hour)")
            assertInside(temperatureFrame, region, "Forecast temperature at \(hour)")
            // The narrow card can clip the bottom precipitation glyphs.
            // Still require each semantic frame to intersect the card.
            if card == .narrow {
                XCTAssertTrue(region.intersects(precipitationFrame), "Precipitation at \(hour) must intersect the forecast region")
                XCTAssertGreaterThanOrEqual(precipitationFrame.minX, region.minX - tolerance)
                XCTAssertLessThanOrEqual(precipitationFrame.maxX, region.maxX + tolerance)
            } else {
                assertInside(precipitationFrame, region, "Forecast precipitation at \(hour)")
            }
            XCTAssertGreaterThanOrEqual(precipitationFrame.minY, temperatureFrame.maxY - tolerance)
            XCTAssertEqual(temperatureFrame.midX, timeFrame.midX, accuracy: tolerance)
            XCTAssertEqual(precipitationFrame.midX, timeFrame.midX, accuracy: tolerance)
            forecast = forecast.union(timeFrame).union(temperatureFrame).union(precipitationFrame)
            hourFrames.append(timeFrame)
        }

        // Forecast weather images share their hour's column below its time.
        let icons = app.images.allElementsBoundByIndex.map(\.frame)
            .filter { $0.minY >= hourFrames[0].maxY - tolerance }
            .sorted { $0.midX < $1.midX }
        XCTAssertEqual(icons.count, hours.count, "Expected a weather image for each forecast hour")
        for (icon, hour) in zip(icons, hourFrames) {
            assertInside(icon, region, "Forecast weather image")
            XCTAssertGreaterThanOrEqual(icon.midX, hour.minX - tolerance)
            XCTAssertLessThanOrEqual(icon.midX, hour.maxX + tolerance)
            forecast = forecast.union(icon)
        }
        return forecast
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
