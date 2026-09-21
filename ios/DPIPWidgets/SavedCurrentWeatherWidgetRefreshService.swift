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
                #if DEBUG
                WidgetWeatherRefreshDiagnostics.log(
                    "clock synchronization started"
                )
                #endif
                #if DEBUG
                let synchronized = await clock.synchronize()
                #else
                _ = await clock.synchronize()
                #endif
                let hasSynchronized = await clock.hasSynchronized
                #if DEBUG
                if synchronized {
                    WidgetWeatherRefreshDiagnostics.log(
                        "clock synchronized"
                    )
                } else if hasSynchronized {
                    WidgetWeatherRefreshDiagnostics.log(
                        "clock failed retainedPreviousAnchor=true"
                    )
                } else {
                    WidgetWeatherRefreshDiagnostics.log(
                        "clock failed retainedPreviousAnchor=false"
                    )
                }
                #endif
                guard hasSynchronized else {
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
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log(
                "location resolution unavailable target="
                    + WidgetWeatherRefreshDiagnostics.targetIdentifier(target)
            )
            #endif
            return .unavailable
        }

        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "location resolved sourceIdentifier="
                + location.address.sourceIdentifier
                + " regionCode=\(location.regionCode)"
        )
        #endif

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
            try writeSnapshot(snapshot)
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("snapshot write succeeded")
            #endif
            return .refreshed
        } catch {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("snapshot write failed")
            #endif
            return .failed
        }
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
                WidgetWeatherRefreshDiagnostics.log(
                    "weather no observation"
                )
            }
            return observation
        } catch {
            WidgetWeatherRefreshDiagnostics.log("weather failed")
            throw error
        }
    }
    #endif
}
