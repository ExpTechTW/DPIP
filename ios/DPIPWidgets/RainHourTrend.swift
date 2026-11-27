import Foundation

/// Next-hour rainfall, one value per minute — the Swift port of the app's
/// `lib/features/weather/domain/rain_hour_trend.dart`. Grading, the summary
/// and the decode rules must stay identical to it: the widget and the Home
/// sheet describe the same hour from the same endpoint.
///
/// The one difference is when the hour is read. The app reads it as fetched;
/// a widget entry is drawn up to an hour after its fetch, so the widget reads
/// only the minutes still ahead of the entry (`summary(elapsedMinutes:)`).
/// At the origin the two readings are the same.
struct RainHourTrend: Codable, Equatable, Sendable {
    static let sampleCount = 60

    /// Peak per-minute mm below which the hour reads as isolated showers.
    static let scatteredMm = 5.0
    /// Peak per-minute mm at which the hour reads as heavy rain.
    static let lightMm = 15.0
    /// The rain is "continuing" when the last wet minute is this late or later.
    static let sustainedFrom = 45

    enum Grade: Equatable, Sendable {
        case none, scattered, light, heavy
    }

    struct Summary: Equatable, Sendable {
        let grade: Grade
        /// Rain still falls near the end of the hour. Light and heavy only.
        let sustained: Bool
        /// Minutes from the moment read until the rain stops: the minute
        /// after the last wet sample. Nil when sustained, scattered or dry.
        let stopInMinutes: Int?
    }

    /// Prediction origin, Unix seconds; the API aligns it to a whole minute.
    let startSecond: Int64
    /// Rainfall for each of the next sixty minutes, mm.
    let mm: [Double]

    /// Nil for anything the chart could not honestly draw: a missing origin,
    /// a sample count other than sixty, or a non-finite or negative value.
    init?(startSecond: Int64, mm: [Double]) {
        guard startSecond > 0,
              mm.count == Self.sampleCount,
              mm.allSatisfy({ $0.isFinite && $0 >= 0 })
        else {
            return nil
        }
        self.startSecond = startSecond
        self.mm = mm
    }

    private enum CodingKeys: String, CodingKey {
        case startSecond, mm
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let trend = Self(
            startSecond: try container.decode(Int64.self, forKey: .startSecond),
            mm: try container.decode([Double].self, forKey: .mm)
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .mm, in: container,
                debugDescription: "Invalid rain trend"
            )
        }
        self = trend
    }

    var startDate: Date {
        Date(timeIntervalSince1970: TimeInterval(startSecond))
    }

    /// The instant the forecast window closes: `start` + 60 minutes.
    var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(Self.sampleCount * 60))
    }

    /// The whole hour, read at its origin: the app's reading.
    var summary: Summary { summary(elapsedMinutes: 0) }

    /// No rain anywhere in the hour.
    var isDry: Bool { summary.grade == .none }

    /// Whole minutes from the origin to `calibratedDate`, truncated toward
    /// zero as Dart's `Duration.inMinutes` does: negative while the origin is
    /// still ahead, sixty or more once the hour is over.
    ///
    /// - Parameter calibratedDate: server time — an entry's device date put
    ///   through its snapshot's `CurrentWeatherWidgetTimeCalibration`. The
    ///   origin is a server stamp, so a device clock off by some minutes
    ///   would move the count, and every reading below, by as many.
    func elapsedMinutes(at calibratedDate: Date) -> Int {
        Int(calibratedDate.timeIntervalSince(startDate) / 60)
    }

    /// The hour as it reads `elapsed` minutes after its origin, from the
    /// minutes still ahead only: the grade, the dry check and the stop all
    /// leave out what has already fallen, and the stop counts from that
    /// moment. A forecast from 15:20 with rain through 15:39 says at 15:21
    /// that it stops in 19 minutes, at 15:30 in 10, and reads dry from 15:40.
    ///
    /// "Sustained" stays where the forecast puts it, in the hour's last
    /// minutes: a stop there cannot be told from the forecast running out,
    /// and the window's end does not move with the entry.
    func summary(elapsedMinutes elapsed: Int) -> Summary {
        // Slice indices stay the hour's own minutes.
        let ahead = mm.dropFirst(max(0, elapsed))
        let peak = ahead.max() ?? 0
        guard peak > 0 else {
            return Summary(grade: .none, sustained: false, stopInMinutes: nil)
        }
        let grade: Grade
        if peak < Self.scatteredMm {
            grade = .scattered
        } else if peak < Self.lightMm {
            grade = .light
        } else {
            grade = .heavy
        }
        guard grade != .scattered,
              let lastRain = ahead.lastIndex(where: { $0 > 0 })
        else {
            return Summary(grade: grade, sustained: false, stopInMinutes: nil)
        }
        let sustained = lastRain >= Self.sustainedFrom
        return Summary(
            grade: grade,
            sustained: sustained,
            stopInMinutes: sustained ? nil : lastRain + 1 - elapsed
        )
    }

    /// The hour at a calibrated instant; see `elapsedMinutes(at:)`.
    func summary(at calibratedDate: Date) -> Summary {
        summary(elapsedMinutes: elapsedMinutes(at: calibratedDate))
    }

    /// No rain ahead of a calibrated instant — true for a finished hour too.
    func isDry(at calibratedDate: Date) -> Bool {
        summary(at: calibratedDate).grade == .none
    }

    /// The calibrated instant the last wet minute ends: from here on the
    /// hour reads dry. Nil when the hour has no rain at all.
    var rainEndDate: Date? {
        mm.lastIndex(where: { $0 > 0 }).map {
            startDate.addingTimeInterval(TimeInterval(($0 + 1) * 60))
        }
    }

    enum DecodeError: Error, Equatable {
        case malformed
    }

    /// The envelope's keys in the order the response lists them, which is
    /// the order Dart's decoded map iterates in. `JSONSerialization` drops
    /// it, so each key is located in the raw text; a key that cannot be found
    /// verbatim (an escaped name) sorts after those that can.
    private static func keysInDocumentOrder(
        _ envelope: [String: Any], _ data: Data
    ) -> [String] {
        let text = String(decoding: data, as: UTF8.self)
        func position(_ key: String) -> Int {
            guard let range = text.range(of: "\"\(key)\"") else { return .max }
            return text.distance(from: text.startIndex, to: range.lowerBound)
        }
        return envelope.keys.sorted {
            let (lhs, rhs) = (position($0), position($1))
            return lhs == rhs ? $0 < $1 : lhs < rhs
        }
    }

    /// Decodes the `rainforecast` envelope exactly as the app does: the first
    /// non-empty series wins; every series empty is the API's "no rain this
    /// hour" and becomes a dry hour starting at `now` (minute-aligned); a
    /// malformed series throws.
    ///
    /// - Parameter now: the device clock, which is what the refresher passes
    ///   — the app passes calibrated time. It only places a dry hour's
    ///   origin, and nothing times against that origin: a dry hour reads dry
    ///   at every instant, so it is never charted and adds no entries, and a
    ///   device clock that is off cannot show anywhere.
    static func decode(_ data: Data, now: Date) throws -> RainHourTrend {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let envelope = object as? [String: Any]
        else {
            throw DecodeError.malformed
        }
        for key in keysInDocumentOrder(envelope, data) {
            guard let series = envelope[key] as? [Any], !series.isEmpty else {
                continue
            }
            guard let record = series.first as? [String: Any],
                  let start = record["start"] as? NSNumber,
                  let rain = record["rain"] as? [Any],
                  rain.count == sampleCount
            else {
                throw DecodeError.malformed
            }
            var values: [Double] = []
            values.reserveCapacity(sampleCount)
            for value in rain {
                guard let number = value as? NSNumber,
                      CFGetTypeID(number) != CFBooleanGetTypeID()
                else {
                    throw DecodeError.malformed
                }
                values.append(number.doubleValue)
            }
            guard let trend = RainHourTrend(
                startSecond: start.int64Value, mm: values
            ) else {
                throw DecodeError.malformed
            }
            return trend
        }
        let seconds = Int64(now.timeIntervalSince1970.rounded(.down))
        return RainHourTrend(
            startSecond: seconds - seconds % 60,
            mm: Array(repeating: 0, count: sampleCount)
        )!
    }
}

/// One target's cached rain trend, tied to the township it was fetched for.
struct RainTrendWidgetSnapshot: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    let schemaVersion: Int
    let sourceIdentifier: String
    let regionCode: String
    let trend: RainHourTrend

    init(sourceIdentifier: String, regionCode: String, trend: RainHourTrend) {
        schemaVersion = Self.schemaVersion
        self.sourceIdentifier = sourceIdentifier
        self.regionCode = regionCode
        self.trend = trend
    }
}

enum RainTrendClientError: Error, Equatable {
    case invalidRegionCode
    case invalidResponse
    case httpStatus(Int)
    case responseTooLarge
}

/// `GET https://exptech.dingbot.tw/api/weather/rainforecast/{code}`.
struct RainTrendClient: Sendable {
    private static let requestTimeout: TimeInterval = 6
    private static let maximumResponseSize = 64 * 1024
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeURL(regionCode: String) throws -> URL {
        guard WidgetResolvedWeatherLocationValidation
            .isValidRegionCode(regionCode)
        else {
            throw RainTrendClientError.invalidRegionCode
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "exptech.dingbot.tw"
        components.path = "/api/weather/rainforecast/\(regionCode)"
        guard let url = components.url else {
            throw RainTrendClientError.invalidRegionCode
        }
        return url
    }

    /// - Parameter now: the origin a dry hour is given; see `decode`.
    func fetch(regionCode: String, now: Date) async throws -> RainHourTrend {
        var request = URLRequest(url: try makeURL(regionCode: regionCode))
        request.httpMethod = "GET"
        request.timeoutInterval = Self.requestTimeout
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw RainTrendClientError.invalidResponse
        }
        guard response.statusCode == 200 else {
            throw RainTrendClientError.httpStatus(response.statusCode)
        }
        guard data.count <= Self.maximumResponseSize else {
            throw RainTrendClientError.responseTooLarge
        }
        return try RainHourTrend.decode(data, now: now)
    }
}
