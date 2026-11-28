import SwiftUI
import XCTest

@testable import Runner

/// The redesigned EEW Live Activity: the content-state contract and every
/// display rule, against the catalog's own text.
@available(iOS 16.1, *)
final class EEWContentStateTests: XCTestCase {
    private typealias State = EEWActivityAttributes.ContentState
    private let epoch = Date(timeIntervalSinceReferenceDate: 800_000_000)

    // MARK: - Contract

    /// A push from before the redesign (Phase 1, #610) still decodes, and
    /// reads as an alert-0, non-final, uncancelled CWA report.
    func testPhaseOnePayloadStillDecodes() throws {
        let json = """
            {"reportNo":2,"originAt":800000000,"magnitude":6.6,"depthKm":10,"epicenter":"花蓮縣近海",
             "reportMaxIntensity":5,"estimatedLocalIntensity":4,"estimatedSArrivalAt":800000028,"waveArrived":false}
            """
        let state = try decode(json)
        XCTAssertEqual(state.reportNo, 2)
        XCTAssertEqual(state.estimatedLocalIntensity, 4)
        XCTAssertNil(state.alert)
        XCTAssertNil(state.isFinal)
        XCTAssertNil(state.cancelled)
        XCTAssertNil(state.rk)
        XCTAssertNil(state.noSource)
        XCTAssertNil(state.localNsspeIntensity)
        XCTAssertNil(state.nsspeMaxIntensity)
        XCTAssertNil(state.firstAlert)
        XCTAssertNil(state.cancelComment)
        XCTAssertEqual(EEWPresentation.kind(for: state), .standard)
        XCTAssertEqual(EEWPresentation.style(for: state, provider: .cwa).background.hex, 0xFFAA00)
        XCTAssertEqual(strings.reportNumber(state), "#2")
    }

    /// The minimal Phase 1 payload: both optionals absent.
    func testPhaseOnePayloadWithoutOptionalsDecodes() throws {
        let state = try decode("""
            {"reportNo":1,"originAt":0,"magnitude":5.7,"depthKm":20,"epicenter":"臺東縣近海",
             "reportMaxIntensity":4,"waveArrived":false}
            """)
        XCTAssertNil(state.estimatedLocalIntensity)
        XCTAssertNil(state.estimatedSArrivalAt)
        XCTAssertEqual(EEWPresentation.arrival(for: state), .unavailable)
    }

    func testEveryFieldDecodesFromItsWireName() throws {
        let state = try decode("""
            {"reportNo":6,"originAt":800000000,"magnitude":7.1,"depthKm":15,"epicenter":"花蓮縣壽豐鄉近海",
             "reportMaxIntensity":8,"estimatedLocalIntensity":7,"estimatedSArrivalAt":800000012,"waveArrived":true,
             "alert":1,"isFinal":true,"cancelled":false,"rk":"4441","noSource":false,
             "localNsspeIntensity":6,"nsspeMaxIntensity":8,"firstAlert":true,"cancelComment":"說明"}
            """)
        XCTAssertEqual(
            state,
            State(
                reportNo: 6, originAt: epoch, magnitude: 7.1, depthKm: 15, epicenter: "花蓮縣壽豐鄉近海",
                reportMaxIntensity: 8, estimatedLocalIntensity: 7, estimatedSArrivalAt: epoch.addingTimeInterval(12),
                waveArrived: true, alert: 1, isFinal: true, cancelled: false, rk: "4441", noSource: false,
                localNsspeIntensity: 6, nsspeMaxIntensity: 8, firstAlert: true, cancelComment: "說明"))
    }

    /// The wire names, pinned. They are not agreed with the server yet; a
    /// rename has to show up here.
    func testWireNamesArePinned() throws {
        let state = State(
            reportNo: 1, originAt: epoch, magnitude: 5, depthKm: 10, epicenter: "x", reportMaxIntensity: 4,
            estimatedLocalIntensity: 3, estimatedSArrivalAt: epoch, waveArrived: false, alert: 0, isFinal: false,
            cancelled: false, rk: "3", noSource: false, localNsspeIntensity: 3, nsspeMaxIntensity: 4,
            firstAlert: false, cancelComment: "c")
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        XCTAssertEqual(
            Set(object.keys),
            [
                "reportNo", "originAt", "magnitude", "depthKm", "epicenter", "reportMaxIntensity",
                "estimatedLocalIntensity", "estimatedSArrivalAt", "waveArrived", "alert", "isFinal", "cancelled",
                "rk", "noSource", "localNsspeIntensity", "nsspeMaxIntensity", "firstAlert", "cancelComment",
            ])
        XCTAssertEqual(try JSONDecoder().decode(State.self, from: JSONEncoder().encode(state)), state)
    }

    /// ActivityKit decodes with a default JSONDecoder: a Date is seconds since
    /// 2001-01-01, so a Unix timestamp would land 31 years late.
    func testDatesAreSecondsSinceTwoThousandOne() throws {
        let state = try decode("""
            {"reportNo":1,"originAt":0,"magnitude":5,"depthKm":10,"epicenter":"x","reportMaxIntensity":4,
             "estimatedSArrivalAt":30,"waveArrived":false}
            """)
        XCTAssertEqual(state.originAt, Date(timeIntervalSinceReferenceDate: 0))
        XCTAssertEqual(state.estimatedSArrivalAt, Date(timeIntervalSinceReferenceDate: 30))
    }

    func testMissingRequiredFieldDoesNotDecode() {
        XCTAssertThrowsError(try decode("""
            {"reportNo":1,"originAt":0,"magnitude":5,"depthKm":10,"epicenter":"x","waveArrived":false}
            """))
    }

    func testMarkingArrivalKeepsEveryOtherField() {
        let state = make(
            alert: 1, isFinal: true, rk: "4", noSource: false, local: 4, localNsspe: 5, nsspeMax: 6,
            firstAlert: true, cancelComment: "c")
        let arrived = state.markingWaveArrived()
        XCTAssertTrue(arrived.waveArrived)
        XCTAssertEqual(
            arrived,
            State(
                reportNo: state.reportNo, originAt: state.originAt, magnitude: state.magnitude,
                depthKm: state.depthKm, epicenter: state.epicenter, reportMaxIntensity: state.reportMaxIntensity,
                estimatedLocalIntensity: state.estimatedLocalIntensity, estimatedSArrivalAt: state.estimatedSArrivalAt,
                waveArrived: true, alert: 1, isFinal: true, cancelled: nil, rk: "4", noSource: false,
                localNsspeIntensity: 5, nsspeMaxIntensity: 6, firstAlert: true, cancelComment: "c"))
    }

    // MARK: - Kind and colours

    func testKindComesFromAlert() {
        XCTAssertEqual(EEWPresentation.kind(for: make(alert: 1)), .emergency)
        XCTAssertEqual(EEWPresentation.kind(for: make(alert: 0)), .standard)
        XCTAssertEqual(EEWPresentation.kind(for: make(alert: nil)), .standard)
        XCTAssertEqual(EEWPresentation.kind(for: make(alert: 1, cancelled: true)), .cancelled)
        XCTAssertEqual(strings.kind(.emergency), "緊急地震速報")
        XCTAssertEqual(strings.kind(.standard), "地震速報")
        XCTAssertEqual(strings.kind(.cancelled), "取消報")
    }

    func testKindColoursAndTints() {
        typealias Expect = (State, EEWPresentation.Provider, UInt32, UInt32, UInt32)
        let cases: [Expect] = [
            // 緊急地震速報: red, white text, whatever the source or precision.
            (make(alert: 1), .cwa, 0xFF0000, 0xFFFFFF, 0x3A0808),
            (make(alert: 1, rk: "1"), .trem, 0xFF0000, 0xFFFFFF, 0x3A0808),
            // CWA 地震速報: orange, black text.
            (make(alert: 0), .cwa, 0xFFAA00, 0x000000, 0x211B04),
            // TREM 地震速報 by precision: usable yellow, low/assumed blue.
            (make(alert: 0, rk: "3"), .trem, 0xFFC800, 0x000000, 0x211B04),
            (make(alert: 0, rk: "4"), .trem, 0xFFC800, 0x000000, 0x211B04),
            (make(alert: 0, rk: "2"), .trem, 0x003264, 0xFFFFFF, 0x07162A),
            (make(alert: 0, rk: "1"), .trem, 0x003264, 0xFFFFFF, 0x07162A),
            (make(alert: 0, rk: "4", noSource: true), .trem, 0x003264, 0xFFFFFF, 0x07162A),
            // 取消報: grey.
            (make(alert: 1, cancelled: true), .trem, 0x48484A, 0xE5E5EA, 0x1C1C1E),
            (make(alert: 0, cancelled: true), .cwa, 0x48484A, 0xE5E5EA, 0x1C1C1E),
        ]
        for (state, provider, background, foreground, tint) in cases {
            let style = EEWPresentation.style(for: state, provider: provider)
            XCTAssertEqual(style.background.hex, background, "\(state)")
            XCTAssertEqual(style.foreground.hex, foreground, "\(state)")
            XCTAssertEqual(style.tint.hex, tint, "\(state)")
        }
    }

    func testProviderIsCaseInsensitiveAndDefaultsToCWA() {
        XCTAssertEqual(EEWPresentation.Provider("trem"), .trem)
        XCTAssertEqual(EEWPresentation.Provider("TREM"), .trem)
        XCTAssertEqual(EEWPresentation.Provider("cwa"), .cwa)
        XCTAssertEqual(EEWPresentation.Provider("CWA"), .cwa)
        XCTAssertEqual(EEWPresentation.Provider(""), .cwa)
        XCTAssertEqual(strings.source(.cwa), "氣象署")
        XCTAssertEqual(strings.source(.trem), "TREM")
    }

    // MARK: - Precision

    func testPrecisionHasExactlyThreeKinds() {
        let cases: [(String?, Bool?, EEWPresentation.Precision)] = [
            ("1111", nil, .low), ("2", nil, .low), ("3", nil, .usable), ("4441", nil, .usable),
            (nil, nil, .low), ("", nil, .low), ("0", nil, .low),
            ("4441", true, .assumed), ("1", true, .assumed), (nil, true, .assumed),
        ]
        for (rk, noSource, expected) in cases {
            XCTAssertEqual(
                EEWPresentation.precision(for: make(rk: rk, noSource: noSource), provider: .trem), expected,
                "rk=\(rk ?? "nil")")
        }
        XCTAssertNil(EEWPresentation.precision(for: make(rk: "4"), provider: .cwa))
        XCTAssertNil(EEWPresentation.precision(for: make(cancelled: true, rk: "/////"), provider: .trem))
        XCTAssertEqual(strings.precision(.assumed), "假定震源")
        XCTAssertEqual(strings.precision(.low), "精度低")
        XCTAssertEqual(strings.precision(.usable), "精度可用")
        XCTAssertEqual(EEWPresentation.precisionDot(.usable).hex, 0xFFC800)
        XCTAssertEqual(EEWPresentation.precisionDot(.low).hex, 0x0064C8)
        XCTAssertEqual(EEWPresentation.precisionDot(.assumed).hex, 0x0064C8)
    }

    // MARK: - nsspe

    func testLocalTownshipInNsspeTakesTheMaximumAndGetsTheRing() {
        // nsspe above the model: it wins, ring on.
        var state = make(local: 4, localNsspe: 5)
        XCTAssertEqual(EEWPresentation.localIntensity(for: state), 5)
        XCTAssertTrue(EEWPresentation.localIsLive(for: state))
        XCTAssertEqual(strings.localLabel(live: true), "所在地・即時")
        // nsspe below the model: the model wins, still listed, ring still on.
        state = make(local: 6, localNsspe: 3)
        XCTAssertEqual(EEWPresentation.localIntensity(for: state), 6)
        XCTAssertTrue(EEWPresentation.localIsLive(for: state))
        // Only nsspe.
        state = make(noSource: true, local: nil, localNsspe: 3)
        XCTAssertEqual(EEWPresentation.localIntensity(for: state), 3)
        XCTAssertTrue(EEWPresentation.localIsLive(for: state))
        // Not listed: model only, no ring.
        state = make(local: 4, localNsspe: nil, nsspeMax: 6)
        XCTAssertEqual(EEWPresentation.localIntensity(for: state), 4)
        XCTAssertFalse(EEWPresentation.localIsLive(for: state))
        XCTAssertEqual(strings.localLabel(live: false), "所在地預估")
        // A cancelled report shows neither.
        state = make(cancelled: true, local: 4, localNsspe: 5)
        XCTAssertNil(EEWPresentation.localIntensity(for: state))
        XCTAssertFalse(EEWPresentation.localIsLive(for: state))
    }

    func testMaximumEstimateTakesNsspeAndShowsDashWhenUndetermined() {
        XCTAssertEqual(EEWPresentation.maxIntensity(for: make(max: 5)), 5)
        XCTAssertEqual(EEWPresentation.maxIntensity(for: make(max: 4, nsspeMax: 6)), 6)
        XCTAssertEqual(EEWPresentation.maxIntensity(for: make(max: 7, nsspeMax: 3)), 7)
        XCTAssertNil(EEWPresentation.maxIntensity(for: make(max: 0)))
        XCTAssertNil(EEWPresentation.maxIntensity(for: make(cancelled: true, max: 5)))
        XCTAssertEqual(strings.maxEstimate(5), "最大預估 5弱")
        XCTAssertEqual(strings.maxEstimate(4), "最大預估 4級")
        XCTAssertEqual(strings.maxEstimate(9), "最大預估 7級")
        XCTAssertEqual(strings.maxEstimate(nil), "最大預估 —")
    }

    // MARK: - Notes

    /// trem-monitor's eew-note: first match wins, texts verbatim.
    func testNotesFollowTremMonitorOrderAndText() {
        typealias Expect = (State, String?)
        let cases: [Expect] = [
            (make(alert: 1, isFinal: true, cancelled: true), "剛剛的緊急地震速報已被取消"),
            (make(cancelled: true, cancelComment: "本報因誤報取消"), "本報因誤報取消"),
            (make(alert: 1, isFinal: true, max: 8, firstAlert: true), "請注意今後的資訊。"),
            (make(alert: 1, max: 7, firstAlert: true), "緊急地震速報的特別警報，請注意自身安全。"),
            (make(alert: 0, max: 3, nsspeMax: 7), "緊急地震速報的特別警報，請注意自身安全。"),
            (make(alert: 0, isFinal: true, max: 7), "緊急地震速報的特別警報，請注意自身安全。"),
            (make(alert: 1, max: 5, nsspeMax: 6, firstAlert: true), "緊急地震速報已發布，請警惕強烈震動。"),
            (make(max: 4, nsspeMax: 5), "因檢測到較大的加速度，故預估震度 5弱。"),
            (make(max: 0, rk: "2", noSource: true, nsspeMax: 3), "因檢測到較大的加速度，故預估震度 3級。"),
            (make(max: 5, nsspeMax: 5), "根據即時數據，直接估算的預估震度。"),
            (make(max: 5, nsspeMax: 2), "根據即時數據，直接估算的預估震度。"),
            (make(max: 3, rk: "1"), "根據即時數據，直接估算的預估震度。"),
            (make(max: 0, rk: "2"), "僅使用了有限數量的觀測點，地震震央的精度可能較低。"),
            (make(alert: 1, max: 5, rk: "4"), "緊急地震速報已發布，請警惕強烈震動。"),
            (make(alert: 0, max: 5, rk: "4"), nil),
            (make(alert: 0, isFinal: true, max: 5, rk: "4"), nil),
        ]
        for (state, expected) in cases {
            let note = EEWPresentation.note(for: state, provider: .trem)
            XCTAssertEqual(note.map(strings.note), expected, "\(state)")
        }
    }

    func testCwaHasNoNoteAndNoDisclaimer() {
        XCTAssertNil(EEWPresentation.note(for: make(alert: 1, max: 9, firstAlert: true), provider: .cwa))
        XCTAssertNil(EEWPresentation.note(for: make(cancelled: true), provider: .cwa))
        XCTAssertFalse(EEWPresentation.showsDisclaimer(.cwa))
        XCTAssertTrue(EEWPresentation.showsDisclaimer(.trem))
        XCTAssertEqual(strings.disclaimer, "最終結果應以氣象署發布之內容為準")
    }

    // MARK: - No source parameters

    func testNoSourceShowsPlaceholdersInTheSameSlots() {
        let state = make(magnitude: 1.0, depth: 10, eta: 30, rk: "2", noSource: true)
        XCTAssertEqual(strings.epicenter(state), "無震源參數推定")
        XCTAssertEqual(strings.magnitude(state), "M—")
        XCTAssertEqual(strings.depth(state), "— km")
        // Its ETA was computed from the placeholder source: never a countdown,
        // and a stale-date does not turn it into 抵達.
        XCTAssertEqual(EEWPresentation.arrival(for: state), .unavailable)
        XCTAssertEqual(EEWPresentation.arrival(for: state, isStale: true), .unavailable)
        XCTAssertEqual(strings.slot(.unavailable), "未提供")
        XCTAssertEqual(strings.arrivalLabel(.unavailable), "震波預計抵達")

        let withSource = make(magnitude: 6.6, depth: 10, eta: 30)
        XCTAssertEqual(strings.epicenter(withSource), "花蓮縣近海")
        XCTAssertEqual(strings.magnitude(withSource), "M6.6")
        XCTAssertEqual(strings.depth(withSource), "10 km")
    }

    func testCancelledReportBlanksItsValues() {
        let state = make(alert: 1, cancelled: true, eta: 30, local: 4)
        XCTAssertEqual(strings.epicenter(state), "—")
        XCTAssertEqual(strings.magnitude(state), "M—")
        XCTAssertEqual(strings.depth(state), "— km")
        XCTAssertEqual(EEWPresentation.arrival(for: state, isStale: true), .cancelled)
        XCTAssertEqual(strings.slot(.cancelled), "取消")
    }

    // MARK: - Arrival

    func testArrivalComesFromStaleDateNotFromZero() {
        let eta = epoch.addingTimeInterval(-5)
        // Past the ETA on the device's clock but not stale: still the timer,
        // resting at 0:00.
        XCTAssertEqual(EEWPresentation.arrival(for: make(eta: -5)), .countdown(eta))
        XCTAssertEqual(EEWPresentation.arrival(for: make(eta: -5), isStale: true), .arrived)
        XCTAssertEqual(EEWPresentation.arrival(for: make(eta: 30), isStale: true), .arrived)
        // A stale-date with no ETA is not an arrival signal.
        XCTAssertEqual(EEWPresentation.arrival(for: make(eta: nil), isStale: true), .unavailable)
        XCTAssertEqual(strings.slot(.arrived), "抵達")
        XCTAssertEqual(strings.arrivalLabel(.arrived), "震波")
        XCTAssertEqual(strings.arrivalLabel(.countdown(eta)), "震波預計抵達")
        XCTAssertNil(strings.slot(.countdown(eta)))
    }

    // MARK: - Text

    func testReportNumbers() {
        XCTAssertEqual(strings.reportNumber(make(report: 3)), "#3")
        XCTAssertEqual(strings.reportNumber(make(report: 6, isFinal: true)), "#6(最終)")
        XCTAssertEqual(strings.reportNumber(make(report: 2, cancelled: true)), "#2(取消)")
        XCTAssertEqual(strings.reportNumber(make(report: 2, isFinal: true, cancelled: true)), "#2(取消)")
    }

    func testIntensityText() {
        XCTAssertEqual((0...9).map { strings.intensity($0) }, ["—", "1級", "2級", "3級", "4級", "5弱", "5強", "6弱", "6強", "7級"])
        XCTAssertEqual(
            (0...9).map { strings.compactIntensity($0) }, ["—", "1", "2", "3", "4", "5弱", "5強", "6弱", "6強", "7"])
        let english = Self.catalogStrings("en")
        XCTAssertEqual((1...9).map { english.intensity($0) }, ["1", "2", "3", "4", "5−", "5+", "6−", "6+", "7"])
        XCTAssertEqual(english.spokenIntensity(5), "Level 5 weak")
        XCTAssertEqual(english.spokenIntensity(nil), "Not determined")
        XCTAssertTrue(EEWIntensityBlock.split("5弱") == ("", "5", "弱"))
        XCTAssertTrue(EEWIntensityBlock.split("4級") == ("", "4", "級"))
        XCTAssertTrue(EEWIntensityBlock.split("Level 5") == ("Level ", "5", ""))
        XCTAssertTrue(EEWIntensityBlock.split("—") == ("", "—", ""))
    }

    func testOriginTimeIsTaiwanTime() {
        // 2026-01-01 00:00:05 UTC is 08:00:05 in Taiwan.
        let date = Date(timeIntervalSince1970: 1_767_225_605)
        XCTAssertEqual(EEWStrings.originTime(date), "08:00:05")
    }

    // MARK: - Layout

    /// iOS cuts a Lock Screen Live Activity off at 160 pt. Every scenario, in
    /// the longest language, at the narrowest and widest phones.
    @MainActor
    func testLockScreenStaysWithinTheSystemHeight() {
        let scenarios: [(String, State)] = [
            ("cwa", make(alert: 0, eta: 28, local: 4)),
            ("cwa", make(alert: 1, isFinal: true, max: 9, eta: 600, local: 9, localNsspe: 9, nsspeMax: 9)),
            ("trem", make(alert: 0, eta: 21, rk: "4", local: 4)),
            ("trem", make(alert: 0, max: 0, eta: 34, rk: "1", local: 0)),
            ("trem", make(magnitude: 1, eta: nil, rk: "2", noSource: true, localNsspe: 3, nsspeMax: 3)),
            ("trem", make(alert: 1, max: 4, eta: 8, rk: "4", local: 4, localNsspe: 5, nsspeMax: 5)),
            ("trem", make(alert: 1, isFinal: true, max: 8, arrived: true, rk: "4", local: 7)),
            ("trem", make(alert: 1, cancelled: true, rk: "/////")),
            ("trem", make(report: 123, epicenter: String(repeating: "花蓮縣壽豐鄉東南方外海", count: 3), max: 8, rk: "4", local: 7)),
        ]
        for language in ["zh-Hant", "en", "ja", "ko", "zh-Hans"] {
            let strings = Self.catalogStrings(language)
            for (provider, state) in scenarios {
                for stale in [false, true] {
                    let report = EEWActivityReport(provider: provider, state: state, isStale: stale, strings: strings)
                    for width in [320.0, 375, 430] {
                        let size = measured(EEWLockScreenView(report: report), width: width)
                        XCTAssertLessThanOrEqual(size.height, 160, "\(language) \(provider) \(state) width=\(width)")
                        XCTAssertLessThanOrEqual(size.width, width + 0.5, "\(language) \(provider) width=\(width)")
                    }
                }
            }
        }
    }

    /// A TREM card keeps its note line even without a note, so the disclaimer
    /// never moves; a CWA card has neither line.
    @MainActor
    func testTremCardHeightDoesNotDependOnTheNote() {
        let withNote = EEWActivityReport(
            provider: "trem", state: make(max: 0, rk: "1"), isStale: false, strings: strings)
        let withoutNote = EEWActivityReport(
            provider: "trem", state: make(alert: 0, max: 5, rk: "4"), isStale: false, strings: strings)
        XCTAssertNotNil(withNote.noteText)
        XCTAssertNil(withoutNote.noteText)
        XCTAssertEqual(
            measured(EEWLockScreenView(report: withNote), width: 375).height,
            measured(EEWLockScreenView(report: withoutNote), width: 375).height, accuracy: 0.5)
        let cwa = EEWActivityReport(provider: "cwa", state: make(), isStale: false, strings: strings)
        XCTAssertLessThan(
            measured(EEWLockScreenView(report: cwa), width: 375).height,
            measured(EEWLockScreenView(report: withNote), width: 375).height)
    }

    // MARK: - Helpers

    private lazy var strings = Self.catalogStrings("zh-Hant")

    /// The widget catalog's own text for one language, so the tests read what
    /// users read instead of keys (the test host bundle has no catalog).
    static func catalogStrings(_ language: String) -> EEWStrings {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("DPIPWidgets/Localizable.xcstrings")
        let catalog = (try? JSONSerialization.jsonObject(with: Data(contentsOf: url))) as? [String: Any]
        let entries = catalog?["strings"] as? [String: [String: Any]] ?? [:]
        var table: [String: String] = [:]
        for (key, entry) in entries {
            let localizations = entry["localizations"] as? [String: [String: Any]]
            if let value = (localizations?[language]?["stringUnit"] as? [String: Any])?["value"] as? String {
                table[key] = value
            }
        }
        return EEWStrings { table[$0] ?? $0 }
    }

    @MainActor
    private func measured<Content: View>(_ content: Content, width: CGFloat) -> CGSize {
        autoreleasepool {
            let host = UIHostingController(rootView: content)
            return host.sizeThatFits(in: CGSize(width: width, height: 1_000))
        }
    }

    private func decode(_ json: String) throws -> State {
        try JSONDecoder().decode(State.self, from: Data(json.utf8))
    }

    private func make(
        report: Int = 3, epicenter: String = "花蓮縣近海", magnitude: Double = 6.6, depth: Double = 10,
        alert: Int? = nil, isFinal: Bool? = nil, cancelled: Bool? = nil, max: Int = 5,
        eta: TimeInterval? = 30, arrived: Bool = false, rk: String? = nil, noSource: Bool? = nil,
        local: Int? = nil, localNsspe: Int? = nil, nsspeMax: Int? = nil, firstAlert: Bool? = nil,
        cancelComment: String? = nil
    ) -> State {
        State(
            reportNo: report, originAt: epoch, magnitude: magnitude, depthKm: depth, epicenter: epicenter,
            reportMaxIntensity: max, estimatedLocalIntensity: local,
            estimatedSArrivalAt: eta.map { epoch.addingTimeInterval($0) }, waveArrived: arrived, alert: alert,
            isFinal: isFinal, cancelled: cancelled, rk: rk, noSource: noSource, localNsspeIntensity: localNsspe,
            nsspeMaxIntensity: nsspeMax, firstAlert: firstAlert, cancelComment: cancelComment)
    }
}
