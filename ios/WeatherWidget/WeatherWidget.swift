//
//  WeatherWidget.swift
//  WeatherWidget
//
//  Created by YuYu 1015 on 11/19/R7.
//  DPIP 天氣桌面小部件
//

import WidgetKit
import SwiftUI

// MARK: - 天氣資料模型
struct WeatherData {
    let weatherStatus: String
    let weatherCode: Int
    let temperature: Double
    let feelsLike: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
    let rain: Double
    let stationName: String
    let stationDistance: Double
    let updateTime: Int
    let hasError: Bool
    let errorMessage: String

    static var placeholder: WeatherData {
        WeatherData(
            weatherStatus: "晴天",
            weatherCode: 1,
            temperature: 25.0,
            feelsLike: 23.0,
            humidity: 65.0,
            windSpeed: 2.5,
            windDirection: "東北",
            rain: 0.0,
            stationName: "中央氣象站",
            stationDistance: 2.5,
            updateTime: Int(Date().timeIntervalSince1970),
            hasError: false,
            errorMessage: ""
        )
    }
}

// MARK: - Timeline Provider
struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), weather: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> ()) {
        let entry = WeatherEntry(date: Date(), weather: loadWeatherData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let weather = loadWeatherData()
        let entry = WeatherEntry(date: currentDate, weather: weather)

        // 設定下次更新時間 (15分鐘後)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // 從 UserDefaults 讀取天氣資料
    private func loadWeatherData() -> WeatherData {
        let sharedDefaults = UserDefaults(suiteName: "group.com.exptech.dpip")

        guard let defaults = sharedDefaults else {
            return WeatherData.placeholder
        }

        let hasError = defaults.bool(forKey: "has_error")

        if hasError {
            let errorMessage = defaults.string(forKey: "error_message") ?? "無法載入天氣"
            return WeatherData(
                weatherStatus: errorMessage,
                weatherCode: 0,
                temperature: 0,
                feelsLike: 0,
                humidity: 0,
                windSpeed: 0,
                windDirection: "-",
                rain: 0,
                stationName: "",
                stationDistance: 0,
                updateTime: 0,
                hasError: true,
                errorMessage: errorMessage
            )
        }

        let temperature = defaults.numberValue(forKey: "temperature") ?? 0
        let feelsLike = defaults.numberValue(forKey: "feels_like") ?? 0
        let humidity = defaults.numberValue(forKey: "humidity") ?? 0
        let windSpeed = defaults.numberValue(forKey: "wind_speed") ?? 0
        let rain = defaults.numberValue(forKey: "rain") ?? 0
        let stationDistance = defaults.numberValue(forKey: "station_distance") ?? 0
        let updateRaw = defaults.numberValue(forKey: "update_time") ?? 0
        let updateSeconds = updateRaw >= 1_000_000_000_000 ? updateRaw / 1000 : updateRaw

        return WeatherData(
            weatherStatus: defaults.string(forKey: "weather_status") ?? "晴天",
            weatherCode: defaults.integer(forKey: "weather_code"),
            temperature: temperature,
            feelsLike: feelsLike,
            humidity: humidity,
            windSpeed: windSpeed,
            windDirection: defaults.string(forKey: "wind_direction") ?? "-",
            rain: rain,
            stationName: defaults.string(forKey: "station_name") ?? "",
            stationDistance: stationDistance,
            updateTime: Int(updateSeconds),
            hasError: false,
            errorMessage: ""
        )
    }
}

private extension UserDefaults {
    func numberValue(forKey key: String) -> Double? {
        if let number = value(forKey: key) as? NSNumber {
            return number.doubleValue
        }
        if let string = string(forKey: key), let value = Double(string) {
            return value
        }
        return nil
    }
}

// MARK: - Timeline Entry
struct WeatherEntry: TimelineEntry {
    let date: Date
    let weather: WeatherData
}

// MARK: - Widget View
struct WeatherWidgetEntryView : View {
    var entry: WeatherProvider.Entry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        contentView()
    }

    @ViewBuilder
    private func contentView() -> some View {
        if entry.weather.hasError {
            errorView()
                .padding()
        } else {
            switch widgetFamily {
            case .systemSmall:
                smallLayout()
                    .padding(12)
            default:
                mediumLayout()
                    .padding(16)
            }
        }
    }

    @ViewBuilder
    private func errorView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.7))

            Text(entry.weather.errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private func mediumLayout() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: getWeatherIcon(code: entry.weather.weatherCode))
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                Text(entry.weather.weatherStatus)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(formatTime(timestamp: entry.weather.updateTime))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }

            VStack(spacing: 6) {
                Text("\(Int(entry.weather.temperature))°")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)

                Text("體感 \(Int(entry.weather.feelsLike))°")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                    InfoItem(label: "濕度", value: "\(Int(entry.weather.humidity))%")
                    InfoItem(label: "風速", value: String(format: "%.1fm/s", entry.weather.windSpeed))
                InfoItem(label: "風向", value: entry.weather.windDirection)
                InfoItem(label: "降雨", value: String(format: "%.1fmm", entry.weather.rain))
            }

            if !entry.weather.stationName.isEmpty {
                Text("\(entry.weather.stationName)氣象站 · \(String(format: "%.1f", entry.weather.stationDistance))km")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    @ViewBuilder
    private func smallLayout() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: getWeatherIcon(code: entry.weather.weatherCode))
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                Text(entry.weather.weatherStatus)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text("\(Int(entry.weather.temperature))°")
                .font(.system(size: 38, weight: .thin))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("體感 \(Int(entry.weather.feelsLike))°")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: 8) {
                MiniInfoItem(label: "濕度", value: "\(Int(entry.weather.humidity))%")
                MiniInfoItem(label: "風速", value: String(format: "%.1fm/s", entry.weather.windSpeed))
            }

            Spacer(minLength: 2)

            Text(formatTime(timestamp: entry.weather.updateTime))
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // 詳細資訊項目
    private func InfoItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func MiniInfoItem(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // 取得天氣圖示
    private func getWeatherIcon(code: Int) -> String {
        switch code {
        case 1: return "sun.max.fill"           // 晴天
        case 2, 3: return "cloud.sun.fill"      // 多雲
        case 4, 5, 6, 7: return "cloud.fill"    // 陰天/霧
        case 8, 9, 10, 11, 12, 13, 14: return "cloud.rain.fill"  // 雨天
        case 15, 16, 17, 18: return "cloud.bolt.rain.fill"       // 雷雨
        default: return "sun.max.fill"
        }
    }

    // 格式化時間
    private func formatTime(timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - Widget Configuration
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            let content = WeatherWidgetEntryView(entry: entry)
            if #available(iOS 17.0, *) {
                content
                    .containerBackground(for: .widget) {
                        WeatherWidget.backgroundGradient
                    }
            } else {
                content
                    .padding(8)
                    .background(
                        WeatherWidget.backgroundGradient
                            .cornerRadius(20)
                    )
                    .padding(4)
            }
        }
        .configurationDisplayName("即時天氣")
        .description("顯示所在地即時天氣資訊")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    private static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.12, green: 0.53, blue: 0.90),
                Color(red: 0.10, green: 0.46, blue: 0.82),
                Color(red: 0.08, green: 0.40, blue: 0.75)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    WeatherWidget()
} timeline: {
    WeatherEntry(date: .now, weather: .placeholder)
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    WeatherWidget()
} timeline: {
    WeatherEntry(date: .now, weather: .placeholder)
}
#endif
