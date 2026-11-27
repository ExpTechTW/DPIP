import WidgetKit

/// Keeps navigation identity independent of the availability of weather data.
struct DPIPWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CurrentWeatherWidgetSnapshot?
    let isStale: Bool
    let isNight: Bool
    let forecast: ForecastWidgetSnapshot?
    let locationTarget: WidgetLocationTarget

    var widgetURL: URL { locationTarget.widgetURL }

    /// Bind the action to configuration, never to cached or gallery weather.
    /// Availability of Button(intent:) is separately gated in the view.
    func forecastRefreshIdentifier(for family: WidgetFamily) -> String? {
        guard ForecastWidgetFamilyPolicy.supportsForecast(family),
              (upcomingForecastPoints(for: family).isEmpty
                  || forecastFreshness == .stale),
              let identifier = locationTarget.sourceIdentifier,
              WidgetLocationTarget(identifier: identifier) == locationTarget else {
            return nil
        }
        return identifier
    }

    /// Evaluated at this entry's own device date, independently of the
    /// Current Weather stale flag and observation-based hour selection.
    var forecastFreshness: ForecastWidgetExpiry.Freshness? {
        guard let snapshot, let forecast,
              forecast.sourceIdentifier == snapshot.sourceIdentifier,
              forecast.regionCode == snapshot.regionCode else { return nil }
        return ForecastWidgetExpiry.freshness(
            of: forecast, at: date,
            calibratedTimeOffsetMilliseconds:
                snapshot.calibratedTimeOffsetMilliseconds
        )
    }

    /// The one mark the header carries beside the observation time.
    enum HeaderCue: Equatable, Sendable {
        /// The current weather is past the stale threshold.
        case staleObservation
        /// The hourly forecast is old enough to doubt.
        case outdatedForecast
    }

    /// An old observation outranks an old forecast: the whole card is out of
    /// date, and the forecast row still marks itself with its refresh button.
    ///
    /// The widget keeps a target's last good reading rather than blanking it
    /// when a refresh fails, so a reading past `isStale` must say so; its
    /// clock alone reads like a current one.
    func headerCue(for family: WidgetFamily) -> HeaderCue? {
        if snapshot != nil, isStale {
            return .staleObservation
        }
        if forecastFreshness == .stale,
           !upcomingForecastPoints(for: family).isEmpty {
            return .outdatedForecast
        }
        return nil
    }

    init(date: Date, snapshot: CurrentWeatherWidgetSnapshot?,
         isStale: Bool, isNight: Bool,
         forecast: ForecastWidgetSnapshot? = nil,
         locationTarget: WidgetLocationTarget = .currentLocation) {
        self.date = date
        self.snapshot = snapshot
        self.isStale = isStale
        self.isNight = isNight
        self.forecast = forecast
        self.locationTarget = locationTarget
    }

    /// Fail closed at the display boundary as well as the cache boundary.
    /// Current weather remains usable independently of forecast availability.
    func upcomingForecastPoints(for family: WidgetFamily) -> [ForecastWidgetPoint] {
        guard let snapshot, let forecast,
              forecast.sourceIdentifier == snapshot.sourceIdentifier,
              forecast.regionCode == snapshot.regionCode,
              ForecastWidgetExpiry.isUsable(
                  forecast, at: date,
                  calibratedTimeOffsetMilliseconds:
                      snapshot.calibratedTimeOffsetMilliseconds
              ) else { return [] }
        let calibratedDate = CurrentWeatherWidgetTimeCalibration(
            snapshot: snapshot
        ).calibratedDate(fromDeviceDate: date)
        return ForecastWidgetFamilyPolicy.visiblePoints(
            in: forecast, at: calibratedDate,
            observationTime: snapshot.observationTime, family: family
        )
    }
}
