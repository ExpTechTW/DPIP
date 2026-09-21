import CryptoKit
import Foundation

enum CurrentWeatherSnapshotWriteResult: Equatable, Sendable {
    case written
    case rejected
}

struct CurrentWeatherSnapshotWriteToken: Equatable, Sendable {
    let address: CurrentWeatherSnapshotAddress
    let generation: Int64
}

enum CurrentWeatherSnapshotStorageError: Error {
    case coordinationFailed
    case invalidOrderingState
    case invalidSnapshot
    case generationExhausted
    case invalidWriteToken
}

protocol CurrentWeatherSnapshotCoordinating: Sendable {
    func coordinate<T>(
        writingItemAt url: URL,
        _ accessor: (URL) throws -> T
    ) throws -> T
}

struct CurrentWeatherSnapshotFileCoordinator:
    CurrentWeatherSnapshotCoordinating
{
    func coordinate<T>(
        writingItemAt url: URL,
        _ accessor: (URL) throws -> T
    ) throws -> T {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var accessorResult: Result<T, Error>?

        coordinator.coordinate(
            writingItemAt: url,
            options: .forReplacing,
            error: &coordinationError
        ) { coordinatedURL in
            accessorResult = Result {
                try accessor(coordinatedURL)
            }
        }

        if let accessorResult {
            return try accessorResult.get()
        }
        if let coordinationError {
            throw coordinationError
        }
        throw CurrentWeatherSnapshotStorageError.coordinationFailed
    }
}

protocol CurrentWeatherSnapshotPersisting: Sendable {
    func write(_ data: Data, to url: URL) throws
}

struct CurrentWeatherSnapshotAtomicPersister:
    CurrentWeatherSnapshotPersisting
{
    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }
}

struct CurrentWeatherSnapshotStorage: Sendable {
    let containerURL: URL
    private let coordinator: any CurrentWeatherSnapshotCoordinating
    private let persister: any CurrentWeatherSnapshotPersisting

    init(
        containerURL: URL,
        coordinator: any CurrentWeatherSnapshotCoordinating =
            CurrentWeatherSnapshotFileCoordinator(),
        persister: any CurrentWeatherSnapshotPersisting =
            CurrentWeatherSnapshotAtomicPersister()
    ) {
        self.containerURL = containerURL
        self.coordinator = coordinator
        self.persister = persister
    }

    func snapshotURL(
        for address: CurrentWeatherSnapshotAddress
    ) -> URL {
        snapshotDirectoryURL
            .appendingPathComponent(address.filename)
    }

    /// Reserves a per-target generation when a logical refresh begins.
    ///
    /// The persisted counter, rather than a wall or monotonic clock, gives
    /// Runner and Widget Extension processes one comparable ordering domain.
    func beginWrite(
        for address: CurrentWeatherSnapshotAddress
    ) throws -> CurrentWeatherSnapshotWriteToken {
        try createDirectories()
        let destination = snapshotURL(for: address)

        return try coordinator.coordinate(
            writingItemAt: destination
        ) { coordinatedDestination in
            let stateURL = orderingStateURL(
                coordinatedSnapshotURL: coordinatedDestination
            )
            let snapshotData = try loadSnapshotData(
                at: coordinatedDestination
            )
            var state = try reconcile(
                loadedState: try loadOrderingState(at: stateURL),
                snapshotData: snapshotData,
                stateURL: stateURL,
                mayAdoptSnapshotWithoutState: true
            )

            guard state.lastIssuedGeneration < Int64.max else {
                throw CurrentWeatherSnapshotStorageError
                    .generationExhausted
            }

            let generation = state.lastIssuedGeneration + 1
            state.lastIssuedGeneration = generation
            try persist(state, to: stateURL)

            return CurrentWeatherSnapshotWriteToken(
                address: address,
                generation: generation
            )
        }
    }

    /// Compares and atomically replaces one canonical target snapshot.
    ///
    /// The sidecar is first marked with a pending commit, then the canonical
    /// snapshot is replaced, and finally the sidecar is committed. Recovery
    /// accepts only the old or pending snapshot fingerprint; any other pairing
    /// fails closed. The snapshot bytes themselves remain the exact schema-v5
    /// payload produced by Dart or Swift.
    func replace(
        _ data: Data,
        using token: CurrentWeatherSnapshotWriteToken
    ) throws -> CurrentWeatherSnapshotWriteResult {
        try createDirectories()
        let destination = snapshotURL(for: token.address)
        let candidateOrdering = try decodeSnapshotOrdering(from: data)

        return try coordinator.coordinate(
            writingItemAt: destination
        ) { coordinatedDestination in
            let stateURL = orderingStateURL(
                coordinatedSnapshotURL: coordinatedDestination
            )
            guard let loadedState = try loadOrderingState(at: stateURL) else {
                throw CurrentWeatherSnapshotStorageError.invalidWriteToken
            }
            let snapshotData = try loadSnapshotData(
                at: coordinatedDestination
            )
            var state = try reconcile(
                loadedState: loadedState,
                snapshotData: snapshotData,
                stateURL: stateURL,
                mayAdoptSnapshotWithoutState: false
            )

            guard
                token.generation > state.rejectedThroughGeneration,
                token.generation <= state.lastIssuedGeneration
            else {
                throw CurrentWeatherSnapshotStorageError.invalidWriteToken
            }

            if let existing = state.committedSnapshot,
               !shouldReplace(
                   address: token.address,
                   existing: existing,
                   candidate: candidateOrdering,
                   candidateGeneration: token.generation
               )
            {
                // A newer same-township acquisition still advances the
                // Current Location identity fence even when its older weather
                // observation cannot replace the canonical snapshot.
                if token.address == .currentLocation,
                   candidateOrdering.regionCode == existing.regionCode,
                   token.generation > existing.locationGeneration
                {
                    state.committedSnapshot = existing.withLocationGeneration(
                        token.generation
                    )
                    try persist(state, to: stateURL)
                }
                return .rejected
            }

            let locationGeneration = locationGeneration(
                address: token.address,
                existing: state.committedSnapshot,
                candidate: candidateOrdering,
                candidateGeneration: token.generation
            )
            let candidateCommit = StoredSnapshotOrdering(
                snapshotGeneration: token.generation,
                locationGeneration: locationGeneration,
                observationTime: candidateOrdering.observationTime,
                regionCode: candidateOrdering.regionCode,
                snapshotSHA256: sha256(data)
            )

            state.pendingCommit = candidateCommit
            try persist(state, to: stateURL)
            try persister.write(data, to: coordinatedDestination)
            state.committedSnapshot = candidateCommit
            state.pendingCommit = nil
            try persist(state, to: stateURL)
            return .written
        }
    }

    private var snapshotDirectoryURL: URL {
        containerURL
            .appendingPathComponent(
                "WidgetSnapshots",
                isDirectory: true
            )
            .appendingPathComponent(
                "current-weather",
                isDirectory: true
            )
    }

    private var orderingDirectoryURL: URL {
        containerURL
            .appendingPathComponent(
                "WidgetSnapshots",
                isDirectory: true
            )
            .appendingPathComponent(
                "current-weather-ordering",
                isDirectory: true
            )
    }

    private func createDirectories() throws {
        try FileManager.default.createDirectory(
            at: snapshotDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: orderingDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    private func orderingStateURL(
        coordinatedSnapshotURL: URL
    ) -> URL {
        // Keep the coordinator-provided filename in case Foundation redirects
        // the coordinated item, while storing ordering outside the canonical
        // cache directory consumed by WidgetSnapshotStore.
        orderingDirectoryURL.appendingPathComponent(
            coordinatedSnapshotURL.lastPathComponent + ".json"
        )
    }

    private func loadSnapshotData(at url: URL) throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return try Data(contentsOf: url)
    }

    private func loadOrderingState(
        at url: URL
    ) throws -> LoadedOrderingState? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let schemaVersion: Int
        do {
            schemaVersion = try JSONDecoder().decode(
                OrderingStateVersion.self,
                from: data
            ).schemaVersion
        } catch {
            throw CurrentWeatherSnapshotStorageError.invalidOrderingState
        }

        do {
            switch schemaVersion {
            case 1:
                let legacy = try JSONDecoder().decode(
                    LegacyOrderingState.self,
                    from: data
                )
                guard legacy.lastIssuedGeneration > 0 else {
                    throw CurrentWeatherSnapshotStorageError
                        .invalidOrderingState
                }
                return .legacy(legacy)
            case 2:
                let state = try JSONDecoder().decode(
                    OrderingState.self,
                    from: data
                )
                try validate(state)
                return .current(state)
            default:
                throw CurrentWeatherSnapshotStorageError
                    .invalidOrderingState
            }
        } catch let error as CurrentWeatherSnapshotStorageError {
            throw error
        } catch {
            throw CurrentWeatherSnapshotStorageError.invalidOrderingState
        }
    }

    private func validate(_ state: OrderingState) throws {
        guard
            state.schemaVersion == 2,
            state.lastIssuedGeneration >= 0,
            state.rejectedThroughGeneration >= 0,
            state.rejectedThroughGeneration <= state.lastIssuedGeneration
        else {
            throw CurrentWeatherSnapshotStorageError.invalidOrderingState
        }

        for ordering in [
            state.committedSnapshot,
            state.pendingCommit,
        ].compactMap({ $0 }) {
            guard
                ordering.snapshotGeneration >= 0,
                ordering.snapshotGeneration <= state.lastIssuedGeneration,
                ordering.locationGeneration >= ordering.snapshotGeneration,
                ordering.locationGeneration <= state.lastIssuedGeneration,
                ordering.snapshotSHA256.count == 64,
                ordering.snapshotSHA256.allSatisfy({
                    $0.isHexDigit && !$0.isUppercase
                })
            else {
                throw CurrentWeatherSnapshotStorageError
                    .invalidOrderingState
            }
        }
    }

    private func reconcile(
        loadedState: LoadedOrderingState?,
        snapshotData: Data?,
        stateURL: URL,
        mayAdoptSnapshotWithoutState: Bool
    ) throws -> OrderingState {
        switch loadedState {
        case nil:
            guard mayAdoptSnapshotWithoutState else {
                throw CurrentWeatherSnapshotStorageError.invalidOrderingState
            }
            let committed = try snapshotData.map {
                try adoptedOrdering(from: $0)
            }
            return OrderingState(
                schemaVersion: 2,
                lastIssuedGeneration:
                    committed?.snapshotGeneration ?? 0,
                rejectedThroughGeneration: 0,
                committedSnapshot: committed,
                pendingCommit: nil
            )

        case .legacy(let legacy):
            let committed = try snapshotData.map {
                try adoptedOrdering(from: $0)
            }
            guard
                (committed?.snapshotGeneration ?? 0)
                    <= legacy.lastIssuedGeneration
            else {
                throw CurrentWeatherSnapshotStorageError.invalidOrderingState
            }
            let migrated = OrderingState(
                schemaVersion: 2,
                lastIssuedGeneration: legacy.lastIssuedGeneration,
                // Tokens issued by the old two-file protocol cannot be proven
                // safe after migration, so only a newly allocated token may
                // commit.
                rejectedThroughGeneration: legacy.lastIssuedGeneration,
                committedSnapshot: committed,
                pendingCommit: nil
            )
            try persist(migrated, to: stateURL)
            return migrated

        case .current(var state):
            if let pending = state.pendingCommit {
                if try snapshotDataMatches(snapshotData, pending) {
                    // The snapshot replacement completed but the final sidecar
                    // update did not. Finish that commit during recovery.
                    state.committedSnapshot = pending
                    state.pendingCommit = nil
                    try persist(state, to: stateURL)
                } else if try snapshotDataMatches(
                    snapshotData,
                    state.committedSnapshot
                ) {
                    // The pending marker landed but the snapshot replacement
                    // did not. Fence every already-issued token through that
                    // generation before allowing a fresh acquisition.
                    state.rejectedThroughGeneration = max(
                        state.rejectedThroughGeneration,
                        pending.snapshotGeneration
                    )
                    state.pendingCommit = nil
                    try persist(state, to: stateURL)
                } else {
                    throw CurrentWeatherSnapshotStorageError
                        .invalidOrderingState
                }
            } else if try !snapshotDataMatches(
                snapshotData,
                state.committedSnapshot
            ) {
                throw CurrentWeatherSnapshotStorageError.invalidOrderingState
            }
            return state
        }
    }

    private func snapshotDataMatches(
        _ data: Data?,
        _ ordering: StoredSnapshotOrdering?
    ) throws -> Bool {
        switch (data, ordering) {
        case (nil, nil):
            return true
        case (.some(let data), .some(let ordering)):
            guard sha256(data) == ordering.snapshotSHA256 else {
                return false
            }
            let decoded = try decodeSnapshotOrdering(from: data)
            return decoded.observationTime == ordering.observationTime
                && decoded.regionCode == ordering.regionCode
        case (.none, .some), (.some, .none):
            return false
        }
    }

    private func adoptedOrdering(
        from data: Data
    ) throws -> StoredSnapshotOrdering {
        let decoded = try decodeSnapshotOrdering(from: data)
        let generation = decoded.legacyGeneration ?? 0
        guard generation >= 0 else {
            throw CurrentWeatherSnapshotStorageError.invalidOrderingState
        }
        return StoredSnapshotOrdering(
            snapshotGeneration: generation,
            locationGeneration: generation,
            observationTime: decoded.observationTime,
            regionCode: decoded.regionCode,
            snapshotSHA256: sha256(data)
        )
    }

    private func persist(
        _ state: OrderingState,
        to url: URL
    ) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try persister.write(encoder.encode(state), to: url)
    }

    private func decodeSnapshotOrdering(
        from data: Data
    ) throws -> SnapshotOrdering {
        do {
            return try JSONDecoder().decode(
                SnapshotOrdering.self,
                from: data
            )
        } catch {
            throw CurrentWeatherSnapshotStorageError.invalidSnapshot
        }
    }

    private func shouldReplace(
        address: CurrentWeatherSnapshotAddress,
        existing: StoredSnapshotOrdering,
        candidate: SnapshotOrdering,
        candidateGeneration: Int64
    ) -> Bool {
        switch address {
        case .currentLocation:
            if candidate.regionCode != existing.regionCode {
                return candidateGeneration > existing.locationGeneration
            }
        case .saved:
            break
        }

        if candidate.observationTime != existing.observationTime {
            return candidate.observationTime > existing.observationTime
        }
        return candidateGeneration > existing.snapshotGeneration
    }

    private func locationGeneration(
        address: CurrentWeatherSnapshotAddress,
        existing: StoredSnapshotOrdering?,
        candidate: SnapshotOrdering,
        candidateGeneration: Int64
    ) -> Int64 {
        guard
            address == .currentLocation,
            let existing,
            candidate.regionCode == existing.regionCode
        else {
            return candidateGeneration
        }
        return max(existing.locationGeneration, candidateGeneration)
    }

    private func sha256(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

private extension CurrentWeatherSnapshotStorage {
    enum LoadedOrderingState {
        case legacy(LegacyOrderingState)
        case current(OrderingState)
    }

    struct OrderingStateVersion: Decodable {
        let schemaVersion: Int
    }

    struct LegacyOrderingState: Decodable {
        let schemaVersion: Int
        let lastIssuedGeneration: Int64
    }

    struct OrderingState: Codable {
        let schemaVersion: Int
        var lastIssuedGeneration: Int64
        var rejectedThroughGeneration: Int64
        var committedSnapshot: StoredSnapshotOrdering?
        var pendingCommit: StoredSnapshotOrdering?
    }

    struct StoredSnapshotOrdering: Codable {
        let snapshotGeneration: Int64
        let locationGeneration: Int64
        let observationTime: Int64
        let regionCode: String
        let snapshotSHA256: String

        func withLocationGeneration(
            _ generation: Int64
        ) -> StoredSnapshotOrdering {
            StoredSnapshotOrdering(
                snapshotGeneration: snapshotGeneration,
                locationGeneration: generation,
                observationTime: observationTime,
                regionCode: regionCode,
                snapshotSHA256: snapshotSHA256
            )
        }
    }

    struct SnapshotOrdering: Decodable {
        let observationTime: Int64
        let regionCode: String
        let legacyGeneration: Int64?

        private enum CodingKeys: String, CodingKey {
            case observationTime
            case regionCode
            case legacyGeneration = "_dpipStorageWriteGeneration"
        }
    }
}
