struct CurrentWeatherSnapshotTime: Equatable, Sendable {
    let calibratedNowUnixMilliseconds: Int64
    let calibratedTimeOffsetMilliseconds: Int
}
