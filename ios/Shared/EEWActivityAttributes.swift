import ActivityKit
import Foundation

/// Phase 1's local-only EEW presentation contract. No production event is
/// converted into this type until its lifecycle semantics are specified.
@available(iOS 16.1, *)
struct EEWActivityAttributes: ActivityAttributes {
    let provider: String
    let eventId: String

    struct ContentState: Codable, Hashable {
        let reportNo: Int
        let originAt: Date
        let magnitude: Double
        let depthKm: Double
        let epicenter: String
        let reportMaxIntensity: Int
        let estimatedLocalIntensity: Int?
        let estimatedSArrivalAt: Date?
        let waveArrived: Bool
    }
}
