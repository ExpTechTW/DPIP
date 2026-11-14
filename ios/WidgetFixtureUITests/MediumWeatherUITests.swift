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

    private enum TextSize: String, CaseIterable {
        case xSmall, small, medium, normal, larger, xxLarge, xxxLarge
        case accessibility, accessibility2, accessibility3, accessibility4, accessibility5

        var isAccessibility: Bool { rawValue.hasPrefix("accessibility") }
    }

    private enum Location: String {
        case short, long, compact, xitun, longChinese, longJapanese, shortJapanese

        var label: String {
            switch self {
            case .short: "Taichung Xitun"
            case .compact: "Xitun"
            case .long: "Taichung City Xitun District Shuinan Central Park"
            case .xitun: "西屯"
            case .longChinese: "臺中市西屯區臺灣大道三段"
            case .longJapanese: "東京都千代田区丸の内一丁目"
            case .shortJapanese: "丸の内"
            }
        }
    }

    private enum Card: String, CaseIterable {
        case narrow, wide

        func size(for family: Family) -> CGSize {
            switch (family, self) {
            case (.small, .narrow): CGSize(width: 158, height: 158)
            case (.small, .wide): CGSize(width: 170, height: 170)
            case (.medium, .narrow): CGSize(width: 338, height: 158)
            case (.medium, .wide): CGSize(width: 364, height: 170)
            case (.large, .narrow): CGSize(width: 319, height: 318)
            case (.large, .wide): CGSize(width: 350, height: 365)
            }
        }
    }

    private enum Family: String {
        case small, medium, large
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

    func testAccessibilityTextWithLongLocationUsesWarningImageAndFiveForecastColumns() {
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

    func testNarrowStaleAndFreshForecastsFitTheirCard() {
        assertStale(.en, location: .longChinese, warningRole: .image,
                    screenshot: "stale-narrow-long-Chinese")
        assertNonStale(.fresh, location: .longChinese, screenshot: "fresh-narrow-long-Chinese")
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
        _ forecast: Forecast, language: Language, size: TextSize, location: Location, card: Card,
        family: Family = .medium, dark: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "DPIP_FIXTURE_FORECAST": forecast.rawValue,
            "DPIP_FIXTURE_LANGUAGE": language.rawValue,
            "DPIP_FIXTURE_TEXT_SIZE": size.rawValue,
            "DPIP_FIXTURE_LOCATION": location.rawValue,
            "DPIP_FIXTURE_CARD": card.rawValue,
            "DPIP_FIXTURE_FAMILY": family.rawValue,
            "DPIP_FIXTURE_DARK": dark ? "1" : "0",
        ]
        app.launch()
        return app
    }

    private func assertStale(
        _ language: Language, size: TextSize = .normal, location: Location = .short,
        card: Card = .narrow, warningRole: XCUIElement.ElementType, screenshot: String? = nil
    ) {
        let app = launch(.stale, language: language, size: size, location: location, card: card)
        capture(screenshot)
        guard let layout = assertCurrentWeather(app, language: language, location: location, card: card) else { return }

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
        let region = forecastBounds(layout.forecast, card: layout.bounds, size: size)
        let refresh = assertRefresh(app, label: language.expected.refresh, region: region)
        guard let forecast = assertForecast(app, region: region, size: size) else { return }
        if let refresh {
            XCTAssertLessThanOrEqual(forecast.maxX, refresh.minX + tolerance, "Forecast must not overlap refresh")
        }
    }

    private func assertNonStale(
        _ forecast: Forecast, language: Language = .en, size: TextSize = .normal,
        location: Location = .short, card: Card = .narrow, screenshot: String? = nil
    ) {
        let app = launch(forecast, language: language, size: size, location: location, card: card)
        capture(screenshot)
        guard let layout = assertCurrentWeather(app, language: language, location: location, card: card) else { return }

        if forecast == .fresh {
            _ = assertForecast(app, region: forecastBounds(layout.forecast, card: layout.bounds, size: size), size: size)
            XCTAssertEqual(app.buttons.count, 0, "Fresh forecast must not offer refresh")
        } else {
            guard let status = requireOne(texts(app, label: language.unavailableLabel), "Forecast unavailable status"),
                  assertRefresh(app, label: language.expected.refresh, region: layout.forecast) != nil else { return }
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
    }

    private func assertCurrentWeather(
        _ app: XCUIApplication, language: Language, location: Location, card: Card, family: Family = .medium
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
        let expectedSize = card.size(for: family)
        XCTAssertEqual(bounds.width, expectedSize.width, accuracy: tolerance)
        XCTAssertEqual(bounds.height, expectedSize.height, accuracy: tolerance)
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
                              width: header.width, height: header.maxY - forecastTop)
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

    private func forecastBounds(_ content: CGRect, card: CGRect, size: TextSize) -> CGRect {
        // The approved regular layout can use some of the lower margin.
        // Still require the entire control and forecast to fit on the card.
        guard !size.isAccessibility else { return content }
        return CGRect(x: content.minX, y: content.minY, width: content.width,
                      height: card.maxY - content.minY)
    }

    private func assertForecast(
        _ app: XCUIApplication, region: CGRect, size: TextSize
    ) -> CGRect? {
        if size.isAccessibility {
            var forecast = CGRect.null
            var previous: CGRect?
            let forecastColumns = app.descendants(matching: .any)
            for (index, hour) in hours.enumerated() {
                let query = forecastColumns.matching(NSPredicate(
                    format: "label BEGINSWITH %@ AND label CONTAINS %@ AND label CONTAINS %@",
                    hour, temperatures[index], probabilities[index]
                ))
                guard let column = requireOne(query, "Complete spoken forecast for \(hour)") else { return nil }
                let frame = column.frame
                assertInside(frame, region, "Forecast column \(hour)")
                if let previous {
                    XCTAssertLessThanOrEqual(previous.maxX, frame.minX + tolerance,
                                             "Forecast columns must not overlap")
                    XCTAssertEqual(previous.minY, frame.minY, accuracy: tolerance)
                }
                previous = frame
                forecast = forecast.union(frame)
            }
            return forecast
        }


        var forecast = CGRect.null
        var hourFrames: [CGRect] = []
        var temperatureFrames: [CGRect] = []
        for (index, hour) in hours.enumerated() {
            guard let time = requireOne(texts(app, label: hour), "Forecast time \(hour)"),
                  let temperature = requireOne(texts(app, label: temperatures[index]), "Forecast temperature at \(hour)"),
                  let precipitation = requireOne(texts(app, label: probabilities[index]), "Forecast precipitation at \(hour)") else { return nil }
            let timeFrame = time.frame
            let temperatureFrame = temperature.frame
            let precipitationFrame = precipitation.frame
            assertInside(timeFrame, region, "Forecast time \(hour)")
            assertInside(temperatureFrame, region, "Forecast temperature at \(hour)")
            assertInside(precipitationFrame, region, "Forecast precipitation at \(hour)")
            XCTAssertGreaterThanOrEqual(precipitationFrame.minY, temperatureFrame.maxY - tolerance)
            XCTAssertEqual(temperatureFrame.midX, timeFrame.midX, accuracy: tolerance)
            if let previous = hourFrames.last {
                XCTAssertGreaterThan(timeFrame.midX, previous.midX)
                XCTAssertEqual(timeFrame.minY, previous.minY, accuracy: tolerance)
            }
            XCTAssertEqual(precipitationFrame.midX, timeFrame.midX, accuracy: tolerance)
            forecast = forecast.union(timeFrame).union(temperatureFrame).union(precipitationFrame)
            hourFrames.append(timeFrame)
            temperatureFrames.append(temperatureFrame)
        }

        // Forecast weather images share their hour's column below its time.
        let icons = app.images.allElementsBoundByIndex.map(\.frame)
            .filter { $0.minY >= hourFrames[0].maxY - tolerance && $0.maxY <= forecast.maxY + tolerance
                && $0.midX <= hourFrames[hours.count - 1].maxX + tolerance }
            .sorted { $0.midX < $1.midX }
        XCTAssertEqual(icons.count, hours.count, "Expected a weather image for each forecast hour")
        for (index, icon) in icons.prefix(hourFrames.count).enumerated() {
            let hour = hourFrames[index]
            let left = index == 0 ? region.minX : (hourFrames[index - 1].midX + hour.midX) / 2
            let right = index == hourFrames.count - 1 ? region.maxX : (hour.midX + hourFrames[index + 1].midX) / 2
            assertInside(icon, region, "Forecast weather image")
            XCTAssertLessThanOrEqual(icon.maxY, temperatureFrames[index].minY + tolerance,
                                     "Weather symbol must remain above its temperature")
            XCTAssertGreaterThanOrEqual(icon.minX, left - tolerance)
            XCTAssertLessThanOrEqual(icon.maxX, right + tolerance)
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

extension MediumWeatherUITests {
    func testLargeStaleHeaderUsesLocalizedText() {
        for language in [Language.traditionalChinese, .en] {
            XCTContext.runActivity(named: language.rawValue) { _ in
                assertLargeStaleHeader(language, location: .compact, card: .wide, warningRole: .staticText)
            }
        }
    }

    func testLargeNarrowJapaneseStaleHeaderUsesLocalizedWarningIcon() {
        assertLargeStaleHeader(.ja, location: .longChinese, card: .narrow, warningRole: .image)
    }

    func testLargeAccessibilityStaleWarningPrecedesObservationTimeInHeader() {
        let scenarios: [(Language, Location, Card)] = [
            (.traditionalChinese, .xitun, .wide),
            (.ja, .longJapanese, .narrow),
            (.en, .long, .narrow),
        ]
        for (language, location, card) in scenarios {
            XCTContext.runActivity(named: "\(language.rawValue)-\(card.rawValue)") { _ in
                let app = launch(.stale, language: language, size: .accessibility, location: location,
                                 card: card, family: .large)
                capture("large-stale-ax1-\(language.rawValue)-\(card.rawValue)")
                guard let layout = assertCurrentWeather(app, language: language, location: location,
                                                        card: card, family: .large),
                      let warning = assertLargeWarning(app, language: language, role: .image) else { return }

                assertHeaderPlacement(app, language: language, warning: warning, bounds: layout.bounds,
                                           location: layout.location, time: layout.time)
                guard let refresh = assertRefresh(app, label: language.expected.refresh, region: layout.forecast),
                      let forecast = assertForecast(app, region: layout.forecast, size: .accessibility) else { return }
                XCTAssertLessThanOrEqual(warning.frame.maxY, forecast.minY + tolerance)
                XCTAssertLessThanOrEqual(forecast.maxX, refresh.minX + tolerance)
            }
        }
    }

    func testLargeNonStaleForecastsExposeNoWarning() {
        let language = Language.traditionalChinese
        for forecast in [Forecast.fresh, .expired, .unavailable] {
            for size in [TextSize.normal, .accessibility] {
                XCTContext.runActivity(named: "\(forecast.rawValue)-\(size.rawValue)") { _ in
                    let app = launch(forecast, language: language, size: size, location: .xitun, card: .wide, family: .large)
                    guard let layout = assertCurrentWeather(app, language: language, location: .xitun,
                                                            card: .wide, family: .large) else { return }
                    if forecast == .fresh {
                        guard assertForecast(app, region: forecastBounds(layout.forecast, card: layout.bounds, size: size), size: size) != nil else { return }
                        XCTAssertEqual(app.buttons.count, 0)
                    } else {
                        guard let status = requireOne(texts(app, label: language.unavailableLabel), "Forecast unavailable status"),
                              assertRefresh(app, label: language.expected.refresh, region: layout.forecast) != nil else { return }
                        assertInside(status.frame, layout.forecast, "Forecast unavailable status")
                    }
                    XCTAssertEqual(warningElements(app, language: language).count, 0,
                                   "Non-stale forecast exposed a stale warning")
                    capture("large-\(forecast.rawValue)-\(size.rawValue)-zh-Hant")
                }
            }
        }
    }

    private func assertLargeStaleHeader(
        _ language: Language, location: Location, card: Card, warningRole: XCUIElement.ElementType
    ) {
        let app = launch(.stale, language: language, size: .normal, location: location, card: card, family: .large)
        guard let layout = assertCurrentWeather(app, language: language, location: location, card: card, family: .large),
              let warning = assertLargeWarning(app, language: language, role: warningRole) else { return }

        assertHeaderPlacement(app, language: language, warning: warning, bounds: layout.bounds,
                                   location: layout.location, time: layout.time)
        _ = assertRefresh(app, label: language.expected.refresh, region: layout.forecast)
        capture("large-stale-\(language.rawValue)")
    }

    private func assertHeaderPlacement(
        _ app: XCUIApplication, language: Language, warning: XCUIElement, bounds: CGRect, location: CGRect, time: CGRect
    ) {
        let frame = warning.frame
        assertInside(frame, bounds.insetBy(dx: margin, dy: margin), "Stale warning")
        XCTAssertLessThanOrEqual(location.maxX, frame.minX + tolerance)
        XCTAssertLessThanOrEqual(frame.maxX, time.minX + tolerance, "Warning must precede observation time")
        XCTAssertGreaterThan(min(frame.maxY, time.maxY), max(frame.minY, time.minY),
                             "Warning and observation time must share a row")
        let labels = [language.expected.warning, language.timeLabel(utcHour: 6)]
        let headerElements = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label IN %@", labels)).allElementsBoundByIndex
        XCTAssertEqual(headerElements.map(\.label), labels, "XCUI tree must list the warning before observation time")
    }

    private func assertLargeWarning(
        _ app: XCUIApplication, language: Language, role: XCUIElement.ElementType
    ) -> XCUIElement? {
        guard let warning = requireOne(warningElements(app, language: language), "Large stale warning") else { return nil }
        XCTAssertEqual(warning.label, language.expected.warning)
        XCTAssertEqual(warning.elementType, role)
        return warning
    }

    private func warningElements(_ app: XCUIApplication, language: Language) -> XCUIElementQuery {
        // Count occurrences in combined labels as well as standalone elements.
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", language.expected.warning))
    }
}

extension MediumWeatherUITests {
    func testMediumDynamicTypeFitsBothCardSizes() {
        assertDynamicTypeMatrix(family: .medium)
    }

    func testLargeDynamicTypeFitsBothCardSizes() {
        assertDynamicTypeMatrix(family: .large)
    }

    private func assertDynamicTypeMatrix(family: Family) {
        let scenarios: [(Language, Location, Location, String)] = [
            (.en, .long, .compact, "Thunder"),
            (.traditionalChinese, .longChinese, .xitun, "雷電"),
            (.ja, .longJapanese, .shortJapanese, "雷"),
        ]
        for card in Card.allCases {
            for (index, size) in TextSize.allCases.enumerated() {
                let (language, long, short, conditionLabel) = scenarios[index % scenarios.count]
                let location = card == .narrow ? long : short
                XCTContext.runActivity(named: "\(family)-\(card)-\(size)-\(language.rawValue)") { _ in
                    let app = launch(.stale, language: language, size: size, location: location,
                                     card: card, family: family, dark: index.isMultiple(of: 2))
                    guard let layout = assertCurrentWeather(app, language: language, location: location,
                                                            card: card, family: family),
                          let condition = requireOne(texts(app, label: conditionLabel), "Current condition"),
                          let warning = requireOne(warningElements(app, language: language), "Stale warning")
                    else { return }
                    let region = forecastBounds(layout.forecast, card: layout.bounds, size: size)
                    guard let refresh = assertRefresh(app, label: language.expected.refresh, region: region),
                          let forecast = assertForecast(app, region: region, size: size) else { return }
                    let content = layout.bounds.insetBy(dx: margin, dy: margin)
                    assertInside(condition.frame, content, "Current condition")
                    assertHeaderPlacement(app, language: language, warning: warning, bounds: layout.bounds,
                                               location: layout.location, time: layout.time)
                    XCTAssertLessThanOrEqual(condition.frame.maxY, forecast.minY + tolerance)
                    XCTAssertLessThanOrEqual(forecast.maxX, refresh.minX + tolerance)
                    if family == .large {
                        assertDetailRows(app, language: language, content: content,
                                         forecastBottom: max(forecast.maxY, refresh.maxY))
                    }
                    capture("\(family)-\(card)-\(size)-\(language.rawValue)")
                }
            }
        }
    }

    private func assertDetailRows(
        _ app: XCUIApplication, language: Language, content: CGRect, forecastBottom: CGFloat
    ) {
        let labels: (humidity: String, rain: String, sunset: String, wind: String, station: String)
        switch language {
        case .en: labels = ("Humidity", "Rainfall", "Sunset", "Wind", "Station")
        case .traditionalChinese: labels = ("濕度", "雨量", "日落", "風", "觀測站")
        case .ja: labels = ("湿度", "降雨量", "日の入り", "風", "観測所")
        default: return XCTFail("Missing fixture expectations for \(language)")
        }
        let details = [(labels.humidity, "100%"), (labels.rain, "123.4 mm"), (labels.sunset, language.timeLabel(utcHour: 8)),
                       (labels.wind, "12.3 m/s"), (labels.station, "Taichung")]
        var omittedDetail = false
        for (index, (label, value)) in details.enumerated() {
            let combined = app.descendants(matching: .any).matching(NSPredicate(
                format: "label BEGINSWITH %@ AND label CONTAINS %@", label, value
            ))
            let frames: [CGRect]
            if combined.count > 0 {
                guard let row = requireOne(combined, "Combined detail '\(label)'") else { return }
                frames = [row.frame]
            } else {
                let key = texts(app, label: label)
                // A short location can have the same label as the station.
                let values = texts(app, label: value).allElementsBoundByIndex.filter {
                    $0.frame.minY >= forecastBottom - tolerance
                }
                if key.count == 0 {
                    XCTAssertTrue(values.isEmpty, "Orphaned value for '\(label)'")
                    XCTAssertGreaterThanOrEqual(index, 3, "Highest priority weather details must fit")
                    omittedDetail = true
                    continue
                }
                guard let name = requireOne(key, "Detail '\(label)'") else { return }
                XCTAssertEqual(values.count, 1, "Detail value '\(value)' must appear exactly once")
                frames = [name.frame] + values.map(\.frame)
            }
            XCTAssertFalse(omittedDetail, "Details must be omitted starting with the lowest priority")
            for frame in frames {
                assertInside(frame, content, "Detail '\(label)'")
                XCTAssertGreaterThanOrEqual(frame.minY, forecastBottom - tolerance)
            }
        }
    }

    func testSmallRegularLayoutHasNoForecastControls() {
        for card in Card.allCases {
            let language = Language.traditionalChinese
            let app = launch(.stale, language: language, size: .normal, location: .xitun, card: card, family: .small)
            guard assertCurrentWeather(app, language: language, location: .xitun, card: card, family: .small) != nil
            else { return }
            XCTAssertEqual(app.buttons.count, 0)
            XCTAssertEqual(warningElements(app, language: language).count, 0)
            XCTAssertEqual(texts(app, label: hours[0]).count, 0)
        }
    }
}
