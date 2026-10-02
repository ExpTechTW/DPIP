struct CurrentLocationCurrentWeatherWidgetRefreshService: Sendable {
    typealias AcquireLocation = @MainActor @Sendable () async
        -> WidgetCurrentLocationResult
    typealias ResolveTownship = @Sendable (
        WidgetCurrentLocation
    ) -> WidgetResolvedWeatherLocation?
    typealias BeginWrite = @Sendable (
        CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherSnapshotWriteToken

    private let acquireLocation: AcquireLocation
    private let resolveTownship: ResolveTownship
    private let beginWrite: BeginWrite
    private let pipeline: CurrentWeatherWidgetRefreshPipeline

    init(
        acquireLocation: @escaping AcquireLocation,
        resolver: WidgetTownshipResolver,
        weatherClient: CurrentWeatherClient,
        clock: WidgetServerClock,
        writer: CurrentWeatherWidgetSnapshotWriter
    ) {
        self.init(
            acquireLocation: acquireLocation,
            resolveTownship: { currentLocation in
                resolver.resolve(currentLocation)
            },
            beginWrite: { address in
                try writer.beginWrite(for: address)
            },
            pipeline: CurrentWeatherWidgetRefreshPipeline(
                weatherClient: weatherClient,
                clock: clock,
                writer: writer
            )
        )
    }

    init(
        acquireLocation: @escaping AcquireLocation,
        resolveTownship: @escaping ResolveTownship,
        beginWrite: @escaping BeginWrite,
        pipeline: CurrentWeatherWidgetRefreshPipeline
    ) {
        self.acquireLocation = acquireLocation
        self.resolveTownship = resolveTownship
        self.beginWrite = beginWrite
        self.pipeline = pipeline
    }

    func refresh() async -> CurrentWeatherWidgetRefreshResult {
        let writeToken: CurrentWeatherSnapshotWriteToken
        do {
            writeToken = try beginWrite(.currentLocation)
        } catch {
            return .failed
        }

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "current location acquisition started"
        )
        #endif

        let currentLocationResult = await acquireLocation()
        let currentLocation: WidgetCurrentLocation
        switch currentLocationResult {
        case .acquired(let acquiredLocation):
            currentLocation = acquiredLocation
        case .unavailable, .timedOut:
            return .unavailable
        case .failed:
            return .failed
        }

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log("township resolution started")
        #endif
        guard let location = resolveTownship(currentLocation),
              location.address == .currentLocation
        else {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log(
                "township resolution unavailable"
            )
            #endif
            return .unavailable
        }
        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "township resolved regionCode=\(location.regionCode)"
        )
        #endif

        return await pipeline.refresh(
            location: location,
            writeToken: writeToken
        )
    }
}
