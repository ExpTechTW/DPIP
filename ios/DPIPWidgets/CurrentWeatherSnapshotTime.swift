git add \
  ios/DPIPWidgets/CurrentWeatherSnapshotTime.swift \
  ios/DPIPWidgets/CurrentWeatherWidgetSnapshot.swift \
  ios/DPIPWidgets/CurrentWeatherWidgetSnapshotFactory.swift \
  ios/DPIPWidgets/SavedWidgetLocationResolver.swift \
  ios/DPIPWidgets/WidgetResolvedWeatherLocation.swift \
  ios/Runner.xcodeproj/project.pbxproj \
  ios/RunnerTests/CurrentWeatherWidgetTests.swift \
  ios/RunnerTests/WidgetLocationCatalogTests.swiftstruct CurrentWeatherSnapshotTime: Equatable, Sendable {
    let calibratedNowUnixMilliseconds: Int64
    let calibratedTimeOffsetMilliseconds: Int
}
