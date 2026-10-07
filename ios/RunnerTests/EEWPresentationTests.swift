import XCTest
@testable import Runner

@available(iOS 16.1, *)
final class EEWPresentationTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 1_000_000)

    func testPersonalizationFallsBackIndependently() {
        for local in [nil, 4] as [Int?] {
            for eta in [nil, epoch] as [Date?] {
                let state = state(local: local, eta: eta)
                XCTAssertEqual(EEWPresentation.intensity(for: state), local ?? 5)
                XCTAssertEqual(EEWPresentation.intensityLabel(for: state),
                               local == nil ? "eew.intensity.max" : "eew.intensity.local")
                XCTAssertEqual(EEWPresentation.arrival(for: state), eta.map { .countdown($0) } ?? .unavailable)
                XCTAssertEqual(state.estimatedLocalIntensity, local)
                XCTAssertEqual(state.estimatedSArrivalAt, eta)
            }
        }
    }

    func testExplicitArrivalWinsWithOrWithoutPersonalization() {
        for local in [nil, 4] as [Int?] {
            for eta in [nil, epoch.addingTimeInterval(-5), epoch.addingTimeInterval(35)] as [Date?] {
                let state = state(local: local, eta: eta, arrived: true)
                XCTAssertEqual(EEWPresentation.arrival(for: state), .arrived)
                XCTAssertEqual(EEWPresentation.intensity(for: state), local ?? 5)
            }
        }
    }

    func testZeroAndExpiredETADoNotInferArrival() {
        for eta in [epoch, epoch.addingTimeInterval(-5)] {
            let state = state(local: nil, eta: eta)
            XCTAssertEqual(EEWPresentation.arrival(for: state), .countdown(eta))
            XCTAssertFalse(state.waveArrived)
        }
    }

    func testDiscreteIntensityTextAndSpokenMapping() {
        for (ordinal, key) in [(5, "5weak"), (6, "5strong"), (7, "6weak"), (8, "6strong")] {
            for compact in [false, true] {
                XCTAssertEqual(EEWPresentation.intensityText(ordinal, compact: compact),
                               .init(key: "eew.intensity." + key, level: nil))
                XCTAssertEqual(EEWPresentation.intensityText(ordinal, compact: compact, spoken: true),
                               .init(key: "eew.intensity." + key + ".spoken", level: nil))
            }
        }
        for (ordinal, level) in [(4, 4), (9, 7)] {
            XCTAssertEqual(EEWPresentation.intensityText(ordinal), .init(key: "eew.intensity.format", level: level))
            XCTAssertEqual(EEWPresentation.intensityText(ordinal, compact: true),
                           .init(key: "eew.intensity.compact.format", level: level))
            XCTAssertEqual(EEWPresentation.intensityText(ordinal, compact: true, spoken: true),
                           .init(key: "eew.intensity.format", level: level))
        }
    }

    func testReportDetailsDoNotChangePrimaryStateSelection() {
        let state = state(local: 8, eta: epoch, report: 123,
                          epicenter: "Long epicenter used only as synthetic layout stress data")
        XCTAssertEqual(state.reportNo, 123)
        XCTAssertEqual(EEWPresentation.intensity(for: state), 8)
        XCTAssertEqual(EEWPresentation.arrival(for: state), .countdown(epoch))
    }

    private func state(local: Int?, eta: Date?, arrived: Bool = false,
                       report: Int = 4, epicenter: String = "Synthetic epicenter") -> EEWActivityAttributes.ContentState {
        .init(reportNo: report, originAt: epoch, magnitude: 6.1, depthKm: 20,
              epicenter: epicenter, reportMaxIntensity: 5, estimatedLocalIntensity: local,
              estimatedSArrivalAt: eta, waveArrived: arrived)
    }
}
