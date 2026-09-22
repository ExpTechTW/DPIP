struct SavedCurrentWeatherWidgetRefreshService: Sendable {
    typealias ResolveLocation = @Sendable (
        WidgetLocationTarget
    ) -> WidgetResolvedWeatherLocation?
    typealias BeginWrite = @Sendable (
        CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherSnapshotWriteToken

    private let resolveLocation: ResolveLocation
    private let beginWrite: BeginWrite
    private let pipeline: CurrentWeatherWidgetRefreshPipeline

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
        resolveLocation: @escaping ResolveLocation,
        beginWrite: @escaping BeginWrite,
        pipeline: CurrentWeatherWidgetRefreshPipeline
    ) {
        self.resolveLocation = resolveLocation
        self.beginWrite = beginWrite
        self.pipeline = pipeline
    }

    func refresh(
        target: WidgetLocationTarget
    ) async -> CurrentWeatherWidgetRefreshResult {
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

        let writeToken: CurrentWeatherSnapshotWriteToken
        do {
            writeToken = try beginWrite(location.address)
        } catch {
            return .failed
        }

        return await pipeline.refresh(
            location: location,
            writeToken: writeToken
        )
    }
}
