enum CurrentWeatherWidgetSnapshotFactory {
    static func make(
        observation: CurrentWeatherRemoteDTO,
        location: WidgetResolvedWeatherLocation,
        time: CurrentWeatherSnapshotTime
    ) -> CurrentWeatherWidgetSnapshot {
        let isNight = WidgetSolarTime.isNight(
            unixMilliseconds: time.calibratedNowUnixMilliseconds,
            latitude: location.latitude,
            longitude: location.longitude
        )

        let nextTransition =
            WidgetSolarTime.nextDayNightTransition(
                unixMilliseconds:
                    time.calibratedNowUnixMilliseconds,
                latitude: location.latitude,
                longitude: location.longitude
            )

        return CurrentWeatherWidgetSnapshot(
            schemaVersion: 5,
            sourceIdentifier: location.address.sourceIdentifier,
            regionCode: location.regionCode,
            regionName: location.regionName,
            observationTime: observation.time,
            stationName: observation.stationName,
            weather: observation.weather,
            weatherCode: observation.weatherCode,
            condition: observation.condition,
            isNight: isNight,
            nextDayNightTransitionTime: Int(nextTransition),
            calibratedTimeOffsetMilliseconds:
                time.calibratedTimeOffsetMilliseconds,
            temperature: observation.temperature,
            humidity: observation.humidity,
            rain: observation.rain
        )
    }
}
