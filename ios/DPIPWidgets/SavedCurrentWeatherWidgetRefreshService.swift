enum SavedCurrentWeatherWidgetRefreshResult: Equatable, Sendable {
    case refreshed
    case noObservation
    case unavailable
    case failed
}

struct SavedCurrentWeatherWidgetRefreshService: Sendable {
    typealias ResolveLocation = @Sendable (
        WidgetLocationTarget
    ) -> WidgetResolvedWeatherLocation?
    typealias FetchWeather = @Sendable (
        Double,
        Double
    ) async throws -> CurrentWeatherRemoteDTO?
    typealias SynchronizeClock = @Sendable () async
        -> CurrentWeatherSnapshotTime?
    typealias WriteSnapshot = @Sendable (
        CurrentWeatherWidgetSnapshot
    ) throws -> Void

    private let resolveLocation: ResolveLocation
    private let fetchWeather: FetchWeather
    private let synchronizeClock: SynchronizeClock
    private let writeSnapshot: WriteSnapshot

    init(
        resolver: SavedWidgetLocationResolver,
        weatherClient: CurrentWeatherClient,
        clock: WidgetServerClock,
        writer: CurrentWeatherWidgetSnapshotWriter
    ) {
        self.init(
            resolveLocation: { target in
                resolver.resolve(target: target)
            },
            fetchWeather: { latitude, longitude in
                try await weatherClient.fetch(
                    latitude: latitude,
                    longitude: longitude
                )
            },
            clock: clock,
            writeSnapshot: { snapshot in
                try writer.write(snapshot)
            }
        )
    }

    init(
        resolveLocation: @escaping ResolveLocation,
        fetchWeather: @escaping FetchWeather,
        clock: WidgetServerClock,
        writeSnapshot: @escaping WriteSnapshot
    ) {
        self.init(
            resolveLocation: resolveLocation,
            fetchWeather: fetchWeather,
            synchronizeClock: {
                _ = await clock.synchronize()
                guard await clock.hasSynchronized else {
                    return nil
                }
                return await clock.currentWeatherSnapshotTime()
            },
            writeSnapshot: writeSnapshot
        )
    }

    init(
        resolveLocation: @escaping ResolveLocation,
        fetchWeather: @escaping FetchWeather,
        synchronizeClock: @escaping SynchronizeClock,
        writeSnapshot: @escaping WriteSnapshot
    ) {
        self.resolveLocation = resolveLocation
        self.fetchWeather = fetchWeather
        self.synchronizeClock = synchronizeClock
        self.writeSnapshot = writeSnapshot
    }

    func refresh(
        target: WidgetLocationTarget
    ) async -> SavedCurrentWeatherWidgetRefreshResult {
        guard let location = resolveLocation(target) else {
            return .unavailable
        }

        async let observation = fetchWeather(
            location.latitude,
            location.longitude
        )
        async let snapshotTime = synchronizeClock()

        do {
            let (resolvedObservation, resolvedSnapshotTime) =
                try await (observation, snapshotTime)

            guard let resolvedObservation else {
                return .noObservation
            }
            guard let resolvedSnapshotTime else {
                return .failed
            }

            let snapshot = CurrentWeatherWidgetSnapshotFactory.make(
                observation: resolvedObservation,
                location: location,
                time: resolvedSnapshotTime
            )
            try writeSnapshot(snapshot)
            return .refreshed
        } catch {
            return .failed
        }
    }
}
