enum CurrentLocationCurrentWeatherWidgetRefreshResult: Equatable, Sendable {
    case refreshed
    case superseded
    case noObservation
    case unavailable
    case failed
}

struct CurrentLocationCurrentWeatherWidgetRefreshService: Sendable {
    typealias AcquireLocation = @MainActor @Sendable () async
        -> WidgetCurrentLocationResult
    typealias ResolveTownship = @Sendable (
        WidgetCurrentLocation
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
    typealias BeginWrite = @Sendable (
        CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherSnapshotWriteToken
    typealias CommitSnapshot = @Sendable (
        CurrentWeatherWidgetSnapshot,
        CurrentWeatherSnapshotWriteToken
    ) throws -> CurrentWeatherSnapshotWriteResult

    private let acquireLocation: AcquireLocation
    private let resolveTownship: ResolveTownship
    private let fetchWeather: FetchWeather
    private let synchronizeClock: SynchronizeClock
    private let beginWrite: BeginWrite
    private let commitSnapshot: CommitSnapshot

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
            fetchWeather: { latitude, longitude in
                try await weatherClient.fetch(
                    latitude: latitude,
                    longitude: longitude
                )
            },
            synchronizeClock: {
                await Self.synchronizedSnapshotTime(clock: clock)
            },
            beginWrite: { address in
                try writer.beginWrite(for: address)
            },
            commitSnapshot: { snapshot, token in
                try writer.write(snapshot, using: token)
            }
        )
    }

    init(
        acquireLocation: @escaping AcquireLocation,
        resolveTownship: @escaping ResolveTownship,
        fetchWeather: @escaping FetchWeather,
        clock: WidgetServerClock,
        writeSnapshot: @escaping WriteSnapshot
    ) {
        self.init(
            acquireLocation: acquireLocation,
            resolveTownship: resolveTownship,
            fetchWeather: fetchWeather,
            synchronizeClock: {
                await Self.synchronizedSnapshotTime(clock: clock)
            },
            writeSnapshot: writeSnapshot
        )
    }

    init(
        acquireLocation: @escaping AcquireLocation,
        resolveTownship: @escaping ResolveTownship,
        fetchWeather: @escaping FetchWeather,
        synchronizeClock: @escaping SynchronizeClock,
        writeSnapshot: @escaping WriteSnapshot
    ) {
        self.init(
            acquireLocation: acquireLocation,
            resolveTownship: resolveTownship,
            fetchWeather: fetchWeather,
            synchronizeClock: synchronizeClock,
            beginWrite: { address in
                CurrentWeatherSnapshotWriteToken(
                    address: address,
                    generation: 1
                )
            },
            commitSnapshot: { snapshot, _ in
                try writeSnapshot(snapshot)
                return .written
            }
        )
    }

    init(
        acquireLocation: @escaping AcquireLocation,
        resolveTownship: @escaping ResolveTownship,
        fetchWeather: @escaping FetchWeather,
        synchronizeClock: @escaping SynchronizeClock,
        beginWrite: @escaping BeginWrite,
        commitSnapshot: @escaping CommitSnapshot
    ) {
        self.acquireLocation = acquireLocation
        self.resolveTownship = resolveTownship
        self.fetchWeather = fetchWeather
        self.synchronizeClock = synchronizeClock
        self.beginWrite = beginWrite
        self.commitSnapshot = commitSnapshot
    }

    func refresh() async -> CurrentLocationCurrentWeatherWidgetRefreshResult {
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

        // Once a township exists, weather and clock synchronization are
        // independent. Starting them together bounds this phase to the slower
        // operation without doing network work for unavailable locations.
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
            "writer attempted sourceIdentifier="
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
                    ? "writer succeeded"
                    : "writer superseded"
            )
            #endif
            return writeResult == .written ? .refreshed : .superseded
        } catch {
            #if DEBUG
            WidgetWeatherRefreshDiagnostics.log("writer failed")
            #endif
            return .failed
        }
    }

    private static func synchronizedSnapshotTime(
        clock: WidgetServerClock
    ) async -> CurrentWeatherSnapshotTime? {
        #if DEBUG
        WidgetWeatherRefreshDiagnostics.log(
            "clock synchronization started"
        )
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
    }

    #if DEBUG
    private func fetchWeatherWithDiagnostics(
        _ location: WidgetResolvedWeatherLocation
    ) async throws -> CurrentWeatherRemoteDTO? {
        WidgetWeatherRefreshDiagnostics.log("weather started")
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
