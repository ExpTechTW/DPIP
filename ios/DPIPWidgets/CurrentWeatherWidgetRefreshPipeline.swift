enum CurrentWeatherWidgetRefreshResult: Equatable, Sendable {
    case refreshed
    case superseded
    case noObservation
    case unavailable
    case failed
}

struct CurrentWeatherWidgetRefreshPipeline: Sendable {
    typealias FetchWeather = @Sendable (
        Double,
        Double
    ) async throws -> CurrentWeatherRemoteDTO?
    typealias SynchronizeClock = @Sendable () async
        -> CurrentWeatherSnapshotTime?
    typealias CommitSnapshot = @Sendable (
        CurrentWeatherWidgetSnapshot,
        CurrentWeatherSnapshotWriteToken
    ) throws -> CurrentWeatherSnapshotWriteResult

    private let fetchWeather: FetchWeather
    private let synchronizeClock: SynchronizeClock
    private let commitSnapshot: CommitSnapshot

    init(
        weatherClient: CurrentWeatherClient,
        clock: WidgetServerClock,
        writer: CurrentWeatherWidgetSnapshotWriter
    ) {
        self.init(
            fetchWeather: { latitude, longitude in
                try await weatherClient.fetch(
                    latitude: latitude,
                    longitude: longitude
                )
            },
            synchronizeClock: {
                await Self.synchronizedSnapshotTime(clock: clock)
            },
            commitSnapshot: { snapshot, token in
                try writer.write(snapshot, using: token)
            }
        )
    }

    init(
        fetchWeather: @escaping FetchWeather,
        synchronizeClock: @escaping SynchronizeClock,
        commitSnapshot: @escaping CommitSnapshot
    ) {
        self.fetchWeather = fetchWeather
        self.synchronizeClock = synchronizeClock
        self.commitSnapshot = commitSnapshot
    }

    func refresh(
        location: WidgetResolvedWeatherLocation,
        writeToken: CurrentWeatherSnapshotWriteToken
    ) async -> CurrentWeatherWidgetRefreshResult {
        #if DEBUG
        async let observation = fetchWeatherWithDiagnostics(location)
        #else
        async let observation = fetchWeather(
            location.latitude,
            location.longitude
        )
        #endif
        async let snapshotTime = synchronizeClock()

        let resolvedObservation: CurrentWeatherRemoteDTO?
        let resolvedSnapshotTime: CurrentWeatherSnapshotTime?
        do {
            (resolvedObservation, resolvedSnapshotTime) = try await (
                observation,
                snapshotTime
            )
        } catch {
            return .failed
        }

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
        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "snapshot write attempted sourceIdentifier="
                + (snapshot.sourceIdentifier ?? "none")
                + " regionCode=\(snapshot.regionCode) "
                + "observationTime=\(snapshot.observationTime)"
        )
        #endif
        do {
            let writeResult = try commitSnapshot(snapshot, writeToken)
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log(
                writeResult == .written
                    ? "snapshot write succeeded"
                    : "snapshot write superseded"
            )
            #endif
            return writeResult == .written ? .refreshed : .superseded
        } catch {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("snapshot write failed")
            #endif
            return .failed
        }
    }

    static func synchronizedSnapshotTime(
        clock: WidgetServerClock
    ) async -> CurrentWeatherSnapshotTime? {
        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log("clock synchronization started")
        let synchronized = await clock.synchronize()
        #else
        _ = await clock.synchronize()
        #endif
        let hasSynchronized = await clock.hasSynchronized
        #if DEBUG
        if synchronized {
            WidgetWeatherRefreshDiagnostics.log("clock synchronized")
        } else {
            WidgetWeatherRefreshDiagnostics.log(
                "clock failed retainedPreviousAnchor=\(hasSynchronized)"
            )
        }
        #endif
        guard hasSynchronized else {
            return nil
        }
        return await clock.currentWeatherSnapshotTime()
    }

    #if DEBUG
    private func fetchWeatherWithDiagnostics(
        _ location: WidgetResolvedWeatherLocation
    ) async throws -> CurrentWeatherRemoteDTO? {
        WidgetWeatherRefreshDiagnostics.log(
            "weather started sourceIdentifier="
                + location.address.sourceIdentifier
        )
        do {
            let observation = try await fetchWeather(
                location.latitude,
                location.longitude
            )
            if let observation {
                WidgetWeatherRefreshDiagnostics.log(
                    "weather observation received observationTime="
                        + "\(observation.time)"
                )
            } else {
                WidgetWeatherRefreshDiagnostics.log("weather no observation")
            }
            return observation
        } catch {
            WidgetWeatherRefreshDiagnostics.log("weather failed")
            throw error
        }
    }
    #endif
}
