import SwiftUI
import WidgetKit

@main
struct WidgetFixtureApp: App {
    private let scenario = WeatherScenario(environment: ProcessInfo.processInfo.environment)
    private let margin: CGFloat = 16

    init() {
        NSTimeZone.default = WeatherScenario.timeZone
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.gray.opacity(0.25).ignoresSafeArea()

                // A sibling of the widget: its accessibility frame cannot grow
                // when the widget's descendants overflow the clipped card.
                Rectangle()
                    .fill(.white)
                    .frame(width: scenario.card.width, height: scenario.card.height)
                    .accessibilityLabel("Fixture presentation boundary")
                    .accessibilityIdentifier("widget-presentation-boundary")

                weatherView
                    .environment(\.locale, scenario.locale)
                    .environment(\.timeZone, WeatherScenario.timeZone)
                    .environment(\.dynamicTypeSize, scenario.dynamicTypeSize)
                    .environment(\.colorScheme, .light)
                    .frame(width: scenario.card.width - 2 * margin, height: scenario.card.height - 2 * margin,
                           alignment: .topLeading)
                    .padding(margin)
                    .clipped()
            }
        }
    }

    @ViewBuilder
    private var weatherView: some View {
        if scenario.family == .large {
            LargeCurrentWeatherView(entry: scenario.entry, localizationBundle: scenario.bundle)
        } else {
            MediumCurrentWeatherView(entry: scenario.entry, localizationBundle: scenario.bundle)
        }
    }
}

private struct WeatherScenario {
    enum Family: String {
        case medium, large
    }

    private enum Card: String {
        case narrow, wide

        func size(for family: Family) -> CGSize {
            switch (family, self) {
            case (.medium, .narrow): CGSize(width: 338, height: 158)
            case (.medium, .wide): CGSize(width: 364, height: 170)
            case (.large, .narrow): CGSize(width: 319, height: 318)
            case (.large, .wide): CGSize(width: 350, height: 365)
            }
        }
    }

    private enum Forecast: String {
        case fresh, stale, expired, unavailable

        var publicationAge: TimeInterval? {
            switch self {
            case .fresh: 15 * 60
            case .stale: 45 * 60
            case .expired: 135 * 60
            case .unavailable: nil
            }
        }
    }

    private enum Language: String {
        case en, traditionalChinese = "zh-Hant", simplifiedChinese = "zh-Hans", ja, ko

        var locale: Locale {
            switch self {
            case .en: Locale(identifier: "en_US")
            case .traditionalChinese: Locale(identifier: "zh_Hant_TW")
            case .simplifiedChinese: Locale(identifier: "zh_Hans_CN")
            case .ja: Locale(identifier: "ja_JP")
            case .ko: Locale(identifier: "ko_KR")
            }
        }

        var bundle: Bundle {
            Bundle(url: Bundle.main.url(forResource: rawValue, withExtension: "lproj")!)!
        }
    }

    private enum TextSize: String {
        case normal, larger, accessibility

        var dynamicTypeSize: DynamicTypeSize {
            switch self {
            case .normal: .large
            case .larger: .xLarge
            case .accessibility: .accessibility1
            }
        }
    }

    private enum Location: String {
        case short, long, compact, xitun, longChinese

        var name: String {
            switch self {
            case .short: "Taichung Xitun"
            case .compact: "Xitun"
            case .long: "Taichung City Xitun District Shuinan Central Park"
            case .xitun: "西屯"
            case .longChinese: "臺中市西屯區臺灣大道三段"
            }
        }
    }

    static let timeZone = TimeZone(identifier: "Asia/Taipei")!
    private let forecast: Forecast
    private let language: Language
    private let textSize: TextSize
    private let location: Location
    let family: Family
    let card: CGSize

    init(environment: [String: String]) {
        family = Self.option("DPIP_FIXTURE_FAMILY", default: .medium, environment: environment)
        forecast = Self.option("DPIP_FIXTURE_FORECAST", default: .stale, environment: environment)
        language = Self.option("DPIP_FIXTURE_LANGUAGE", default: .en, environment: environment)
        textSize = Self.option("DPIP_FIXTURE_TEXT_SIZE", default: .normal, environment: environment)
        location = Self.option("DPIP_FIXTURE_LOCATION", default: .short, environment: environment)
        card = Self.option("DPIP_FIXTURE_CARD", default: Card.narrow, environment: environment).size(for: family)
    }

    private static func option<Value: RawRepresentable>(
        _ key: String, default defaultValue: Value, environment: [String: String]
    ) -> Value where Value.RawValue == String {
        guard let rawValue = environment[key] else { return defaultValue }
        guard let value = Value(rawValue: rawValue) else {
            preconditionFailure("Unsupported WidgetFixture option \(key)=\(rawValue)")
        }
        return value
    }

    var locale: Locale { language.locale }
    var bundle: Bundle { language.bundle }
    var dynamicTypeSize: DynamicTypeSize { textSize.dynamicTypeSize }

    var entry: DPIPWidgetEntry {
        // 15:21 entry date and 14:21 observation, both in Taipei.
        let date = ISO8601DateFormatter().date(from: "2026-09-25T07:21:00Z")!
        let observationDate = date.addingTimeInterval(-3600)
        let snapshot = CurrentWeatherWidgetSnapshot(
            schemaVersion: 7, sourceIdentifier: "current-location", regionCode: "407",
            regionName: location.name, observationTime: Int(observationDate.timeIntervalSince1970),
            stationName: "Taichung", weather: "雷雨", weatherCode: 319, condition: .thunderstorm,
            isNight: false, nextDayNightTransitionTime: Int(date.addingTimeInterval(3600).timeIntervalSince1970),
            calibratedTimeOffsetMilliseconds: 0, temperature: 32, humidity: 100, rain: 123.4,
            windDirection: "NE", windSpeed: 12.3, apparentTemperature: 38
        )
        let forecastSnapshot = forecast.publicationAge.map { age in
            ForecastWidgetSnapshot(
                sourceIdentifier: "current-location", regionCode: "407",
                updateTime: Int64(date.addingTimeInterval(-age).timeIntervalSince1970 * 1000),
                receivedAt: Int64(date.timeIntervalSince1970 * 1000),
                points: (16...20).map { hour in
                    ForecastWidgetPoint(
                        time: "\(hour):00", temperature: Double(hour + 6),
                        weather: "晴", weatherCode: 100, pop: (hour - 14) * 10
                    )!
                }
            )!
        }
        return DPIPWidgetEntry(date: date, snapshot: snapshot, isStale: false, isNight: false, forecast: forecastSnapshot)
    }
}
