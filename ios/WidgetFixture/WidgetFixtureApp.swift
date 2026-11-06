import SwiftUI
import WidgetKit

@main struct WidgetProofApp: App {
    init() { NSTimeZone.default = TimeZone(identifier: "Asia/Taipei")! }
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.gray.opacity(0.25).ignoresSafeArea()
                MediumCurrentWeatherView(entry: fixture, localizationBundle: Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)!)
                    .environment(\.locale, Locale(identifier: "en_US"))
                    .environment(\.timeZone, TimeZone(identifier: "Asia/Taipei")!)
                    .environment(\.colorScheme, .light)
                    .frame(width: 306, height: 126, alignment: .topLeading)
                    .padding(16)
                    .background(Color.white)
                    .frame(width: 338, height: 158)
                    .clipped()
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("widget-card")
            }
        }
    }
}
let date = ISO8601DateFormatter().date(from: "2026-09-25T07:21:00Z")!
let snapshot = CurrentWeatherWidgetSnapshot(schemaVersion: 7, sourceIdentifier: "current-location", regionCode: "407", regionName: "Taichung Xitun", observationTime: Int(date.addingTimeInterval(-3600).timeIntervalSince1970), stationName: "Taichung", weather: "雷雨", weatherCode: 319, condition: .thunderstorm, isNight: false, nextDayNightTransitionTime: Int(date.addingTimeInterval(3600).timeIntervalSince1970), calibratedTimeOffsetMilliseconds: 0, temperature: 32, humidity: 100, rain: 123.4, windDirection: "NE", windSpeed: 12.3, apparentTemperature: 38)
let forecast = ForecastWidgetSnapshot(sourceIdentifier: "current-location", regionCode: "407", updateTime: Int64(date.addingTimeInterval(-2700).timeIntervalSince1970 * 1000), receivedAt: Int64(date.timeIntervalSince1970 * 1000), points: ["16:00", "17:00", "18:00", "19:00", "20:00"].map { ForecastWidgetPoint(time: $0, temperature: 22, weather: "晴", weatherCode: 100, pop: 20)! })!
let fixture = DPIPWidgetEntry(date: date, snapshot: snapshot, isStale: false, isNight: false, forecast: forecast)
