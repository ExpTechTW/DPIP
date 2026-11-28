import SwiftUI
import XCTest

@testable import Runner

/// The EEW Live Activity's content state — the §2 string in `d` — and every
/// display rule (notify-server-go `docs/LIVE_ACTIVITY_PAYLOAD.md` §2–§3.1),
/// against the catalog's own text.
@available(iOS 16.1, *)
final class EEWContentStateTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_795_888_105)

    // MARK: - Contract

    /// The content state is `{"d": "…"}` and nothing else.
    func testContentStateIsTheStringAlone() throws {
        let state = try JSONDecoder().decode(
            EEWActivityAttributes.ContentState.self, from: Data(#"{"d":"1|3|0|1795888105"}"#.utf8))
        XCTAssertEqual(state.d, "1|3|0|1795888105")
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["d"])
        XCTAssertThrowsError(try JSONDecoder().decode(EEWActivityAttributes.ContentState.self, from: Data("{}".utf8)))
    }

    func testParsesEveryTremField() throws {
        let payload = try XCTUnwrap(EEWPayload("1|3|9|1795888105|22.78|121.38|臺東縣近海|6.2|20|4|5|2|5", provider: "trem"))
        XCTAssertEqual(
            payload,
            EEWPayload(
                source: .trem, serial: 3, flags: [.alert, .hasNsspe], origin: origin, latitude: 22.78,
                longitude: 121.38, epicenter: "臺東縣近海", magnitude: 6.2, depthKm: 20, rk: 4, maxIntensity: 5,
                firstAlertSerial: 2, localNsspe: 5))
        XCTAssertTrue(payload.isAlert)
        XCTAssertFalse(payload.isFinal)
        XCTAssertFalse(payload.isCancelled)
    }

    func testParsesEveryCwaField() throws {
        let payload = try XCTUnwrap(EEWPayload("1|2|3|1795888105|23.85|121.62|花蓮縣壽豐鄉近海|6.4|15|6", provider: "CWA"))
        XCTAssertEqual(
            payload,
            EEWPayload(
                source: .cwa, serial: 2, flags: [.alert, .finalReport], origin: origin, latitude: 23.85,
                longitude: 121.62, epicenter: "花蓮縣壽豐鄉近海", magnitude: 6.4, depthKm: 15, maxIntensity: 6))
        // CWA has no TREM fields, even if a sender appended some.
        let extended = try XCTUnwrap(EEWPayload("1|2|0|1795888105|23.85|121.62|x|6.4|15|6|4|2|5", provider: "cwa"))
        XCTAssertNil(extended.rk)
        XCTAssertNil(extended.firstAlertSerial)
        XCTAssertNil(extended.localNsspe)
    }

    /// Empty is "no value", which for an intensity is "not determined" and
    /// never 0; a short string reads its missing fields as empty; extra
    /// fields are ignored; an unknown version is not shown at all.
    func testEmptyMissingAndExtraFields() throws {
        let cancelled = try XCTUnwrap(EEWPayload("1|2|4|1795888105|||||||||0", provider: "trem"))
        XCTAssertNil(cancelled.latitude)
        XCTAssertNil(cancelled.longitude)
        XCTAssertNil(cancelled.epicenter)
        XCTAssertNil(cancelled.magnitude)
        XCTAssertNil(cancelled.depthKm)
        XCTAssertNil(cancelled.rk)
        XCTAssertNil(cancelled.maxIntensity)
        XCTAssertNil(cancelled.firstAlertSerial)
        XCTAssertEqual(cancelled.localNsspe, 0)

        let short = try XCTUnwrap(EEWPayload("1|5", provider: "trem"))
        XCTAssertEqual(short.serial, 5)
        XCTAssertEqual(short.flags, [])
        XCTAssertNil(short.origin)
        XCTAssertNil(short.localNsspe)

        let longer = try XCTUnwrap(EEWPayload("1|3|0|1795888105|23.95|121.71|花蓮縣近海|5.8|20|4|4||0|9|x", provider: "trem"))
        XCTAssertEqual(longer.localNsspe, 0)

        XCTAssertNil(EEWPayload("2|3|0|1795888105", provider: "trem"))
        XCTAssertNil(EEWPayload("", provider: "trem"))
        XCTAssertNil(EEWPayload("|1|0", provider: "cwa"))

        // A field that is not a number is no value, not a crash.
        let garbled = try XCTUnwrap(EEWPayload("1|x|0|y|23.9|nan|e|M|20|a|b", provider: "trem"))
        XCTAssertNil(garbled.serial)
        XCTAssertNil(garbled.origin)
        XCTAssertNil(garbled.longitude)
        XCTAssertNil(garbled.magnitude)
        XCTAssertNil(garbled.rk)
        XCTAssertNil(garbled.maxIntensity)
    }

    func testProviderIsCaseInsensitiveAndDefaultsToCWA() {
        XCTAssertEqual(EEWPayload.Source(provider: "trem"), .trem)
        XCTAssertEqual(EEWPayload.Source(provider: "TREM"), .trem)
        XCTAssertEqual(EEWPayload.Source(provider: "cwa"), .cwa)
        XCTAssertEqual(EEWPayload.Source(provider: ""), .cwa)
        XCTAssertEqual(strings.source(.cwa), "氣象署")
        XCTAssertEqual(strings.source(.trem), "TREM")
    }

    // MARK: - Kind, colour, precision

    func testKindColoursAndTints() throws {
        let cases: [(String, String, UInt32, UInt32, UInt32, String)] = [
            ("trem", "1|3|1|1795888105|1|1|x|5|10|1|4||0", 0xFF0000, 0xFFFFFF, 0x3A0808, "緊急地震速報"),
            ("cwa", "1|3|1|1795888105|1|1|x|5|10|4", 0xFF0000, 0xFFFFFF, 0x3A0808, "緊急地震速報"),
            ("cwa", "1|3|0|1795888105|1|1|x|5|10|4", 0xFFAA00, 0x000000, 0x211B04, "地震速報"),
            ("trem", "1|3|0|1795888105|1|1|x|5|10|3|4||0", 0xFFC800, 0x000000, 0x211B04, "地震速報"),
            ("trem", "1|3|0|1795888105|1|1|x|5|10|4|4||0", 0xFFC800, 0x000000, 0x211B04, "地震速報"),
            ("trem", "1|3|0|1795888105|1|1|x|5|10|2|4||0", 0x003264, 0xFFFFFF, 0x07162A, "地震速報"),
            ("trem", "1|3|0|1795888105|1|1|x|1.0|10|4|4||0", 0x003264, 0xFFFFFF, 0x07162A, "地震速報"),
            ("trem", "1|3|0|1795888105|1|1|x|5|10||4||0", 0x003264, 0xFFFFFF, 0x07162A, "地震速報"),
            ("trem", "1|3|5|1795888105|||||||||0", 0x48484A, 0xE5E5EA, 0x1C1C1E, "取消報"),
            ("cwa", "1|3|4|1795888105||||||", 0x48484A, 0xE5E5EA, 0x1C1C1E, "取消報"),
        ]
        for (provider, d, background, foreground, tint, kind) in cases {
            let payload = try XCTUnwrap(EEWPayload(d, provider: provider))
            let style = EEWPresentation.style(for: payload)
            XCTAssertEqual(style.background.hex, background, d)
            XCTAssertEqual(style.foreground.hex, foreground, d)
            XCTAssertEqual(style.tint.hex, tint, d)
            XCTAssertEqual(strings.kind(EEWPresentation.kind(for: payload)), kind, d)
        }
    }

    func testPrecisionHasExactlyThreeKinds() throws {
        let cases: [(String, EEWPresentation.Precision?)] = [
            ("1|1|0|1795888105|1|1|x|5|10|1|4||0", .low),
            ("1|1|0|1795888105|1|1|x|5|10|2|4||0", .low),
            ("1|1|0|1795888105|1|1|x|5|10|3|4||0", .usable),
            ("1|1|0|1795888105|1|1|x|5|10|4|4||0", .usable),
            ("1|1|0|1795888105|1|1|x|1.0|10|4|4||0", .assumed),
            ("1|1|0|1795888105|1|1|x|5|10||4||0", nil),
            ("1|1|0|1795888105|1|1|x|5|10|0|4||0", nil),
            ("1|1|4|1795888105|||||||||0", nil),
        ]
        for (d, expected) in cases {
            XCTAssertEqual(EEWPresentation.precision(for: try XCTUnwrap(EEWPayload(d, provider: "trem"))), expected, d)
        }
        XCTAssertNil(EEWPresentation.precision(for: try XCTUnwrap(EEWPayload("1|1|0|1795888105|1|1|x|5|10|4", provider: "cwa"))))
        XCTAssertEqual(strings.precision(.assumed), "假定震源")
        XCTAssertEqual(strings.precision(.low), "精度低")
        XCTAssertEqual(strings.precision(.usable), "精度可用")
        XCTAssertEqual(EEWPresentation.precisionDot(.usable).hex, 0xFFC800)
        XCTAssertEqual(EEWPresentation.precisionDot(.low).hex, 0x0064C8)
    }

    // MARK: - Intensities

    /// §3: the report's own maximum, as is: empty is 「—」, and 0 is "not
    /// felt", 「0級」 — not the same thing.
    func testMaximumEstimate() throws {
        let cases: [(String, String, String)] = [
            ("trem", "1|3|0|1795888105|1|1|x|5|10|4|4||0", "最大預估 4級"),
            ("trem", "1|3|0|1795888105|1|1|x|5|10|4|6||0", "最大預估 5強"),
            ("trem", "1|3|0|1795888105|1|1|x|5|10|4|||0", "最大預估 —"),
            ("trem", "1|2|0|1795888105|24.50|121.90|宜蘭縣外海|4.0|30|3|0||0", "最大預估 0級"),
            ("trem", "1|3|0|1795888105|1|1|x|5|10|4", "最大預估 —"),
            ("trem", "1|3|4|1795888105|||||||||0", "最大預估 —"),
            ("cwa", "1|3|0|1795888105|1|1|x|5|10|0", "最大預估 0級"),
            ("cwa", "1|3|0|1795888105|1|1|x|5|10|9", "最大預估 7級"),
            ("cwa", "1|3|0|1795888105|1|1|x|5|10|", "最大預估 —"),
        ]
        for (provider, d, expected) in cases {
            let payload = try XCTUnwrap(EEWPayload(d, provider: provider))
            XCTAssertEqual(strings.maxEstimate(EEWPresentation.maxIntensity(for: payload)), expected, d)
        }
    }

    func testLocalIntensityAndRing() throws {
        func local(_ d: String, _ provider: String = "trem", estimate scale: Int?) throws -> (String, Bool) {
            let payload = try XCTUnwrap(EEWPayload(d, provider: provider))
            let estimate = scale.map { EEWLocalShaking.Estimate(scale: $0, intensity: Double($0), sArrivalMs: 5000) }
            return (
                strings.intensity(EEWPresentation.localIntensity(for: payload, estimate: estimate)),
                EEWPresentation.localIsLive(for: payload))
        }
        // TREM: max(estimate, local nsspe); the ring whenever nsspe lists us.
        XCTAssertTrue(try local("1|3|9|1795888105|22.78|121.38|x|6.2|20|4|4|2|5", estimate: 3) == ("5弱", true))
        XCTAssertTrue(try local("1|3|9|1795888105|22.78|121.38|x|6.2|20|4|4|2|2", estimate: 6) == ("5強", true))
        XCTAssertTrue(try local("1|3|0|1795888105|22.78|121.38|x|6.2|20|4|4||0", estimate: 0) == ("0級", false))
        XCTAssertTrue(try local("1|3|0|1795888105|22.78|121.38|x|6.2|20|4|4||0", estimate: nil) == ("—", false))
        XCTAssertTrue(try local("1|3|8|1795888105|22.78|121.38|x|6.2|20|4|4||3", estimate: nil) == ("3級", true))
        // No source parameters: local nsspe alone, and its 0 is "not listed".
        XCTAssertTrue(try local("1|1|8|1795888105|23.99|121.60|花蓮縣|1.0|10|2|||3", estimate: 6) == ("3級", true))
        XCTAssertTrue(try local("1|1|0|1795888105|23.99|121.60|花蓮縣|1.0|10|2|||0", estimate: 6) == ("—", false))
        // CWA: the estimate; never a ring.
        XCTAssertTrue(try local("1|2|1|1795888105|23.85|121.62|x|6.4|15|6", "cwa", estimate: 6) == ("5強", false))
        // A cancellation has none.
        XCTAssertTrue(try local("1|2|4|1795888105|||||||||5", estimate: 4) == ("—", false))
        XCTAssertEqual(strings.localLabel(live: true), "所在地・即時")
        XCTAssertEqual(strings.localLabel(live: false), "所在地預估")
    }

    // MARK: - Notes

    /// §3.1: trem-monitor's order, this format's fields, texts verbatim.
    /// "Model" is the app's own estimate for the township (none, or no
    /// source parameters, counts as 0); an empty maximum counts as 0.
    func testNotesFollowTheSpecOrderAndText() throws {
        let cases: [(String, Int?, String?)] = [
            ("1|2|7|1795888105|||||||||0", nil, "剛剛的緊急地震速報已被取消"),
            ("1|6|3|1795888105|1|1|x|7.1|15|4|8|2|0", 7, "請注意今後的資訊。"),
            ("1|4|1|1795888105|1|1|x|7.1|15|4|8|2|0", 7, "緊急地震速報的特別警報，請注意自身安全。"),
            ("1|4|2|1795888105|1|1|x|5|15|4|7||0", 3, "緊急地震速報的特別警報，請注意自身安全。"),
            ("1|2|9|1795888105|1|1|x|6.2|20|4|6|2|5", 3, "緊急地震速報已發布，請警惕強烈震動。"),
            // ④: the township's nsspe above the app's estimate for it.
            ("1|3|9|1795888105|1|1|x|6.2|20|4|5|2|5", 3, "因檢測到較大的加速度，故預估震度 5弱。"),
            ("1|3|9|1795888105|1|1|x|6.2|20|4|5|2|5", nil, "因檢測到較大的加速度，故預估震度 5弱。"),
            ("1|1|8|1795888105|1|1|x|1.0|10|2|3||3", 6, "因檢測到較大的加速度，故預估震度 3級。"),
            // ⑤ once the estimate reaches the nsspe level.
            ("1|3|9|1795888105|1|1|x|6.2|20|4|5|2|5", 5, "根據即時數據，直接估算的預估震度。"),
            ("1|3|8|1795888105|1|1|x|5|20|4|5||0", 3, "根據即時數據，直接估算的預估震度。"),
            ("1|3|0|1795888105|1|1|x|5|20|1|3||0", 3, "根據即時數據，直接估算的預估震度。"),
            ("1|1|0|1795888105|1|1|x|4.6|10|1|||0", 3, "僅使用了有限數量的觀測點，地震震央的精度可能較低。"),
            ("1|1|0|1795888105|1|1|x|4.6|10|2|0||0", 3, "僅使用了有限數量的觀測點，地震震央的精度可能較低。"),
            ("1|3|1|1795888105|1|1|x|5|20|4|5|2|0", 4, "緊急地震速報已發布，請警惕強烈震動。"),
            ("1|3|1|1795888105|1|1|x|5|20|4|5||0", 4, "緊急地震速報已發布，請警惕強烈震動。"),
            ("1|3|0|1795888105|1|1|x|5|20|4|5||0", 4, nil),
            ("1|3|2|1795888105|1|1|x|5|20|4|5||0", 4, nil),
            // ③ needs the serial itself: no serial, no match.
            ("1||1|1795888105|1|1|x|5|20|4|5||0", 4, "緊急地震速報已發布，請警惕強烈震動。"),
            ("1||0|1795888105|1|1|x|5|20|4|5||0", 4, nil),
        ]
        for (d, scale, expected) in cases {
            let payload = try XCTUnwrap(EEWPayload(d, provider: "trem"))
            let estimate = scale.map { EEWLocalShaking.Estimate(scale: $0, intensity: Double($0), sArrivalMs: 5000) }
            XCTAssertEqual(
                EEWPresentation.note(for: payload, estimate: estimate).map(strings.note), expected,
                "\(d) estimate \(String(describing: scale))")
        }
    }

    func testCwaHasNoNoteAndNoDisclaimer() throws {
        let cwa = try XCTUnwrap(EEWPayload("1|2|5|1795888105|1|1|x|7.1|15|9", provider: "cwa"))
        XCTAssertNil(EEWPresentation.note(for: cwa, estimate: nil))
        XCTAssertFalse(EEWPresentation.showsDisclaimer(cwa))
        XCTAssertTrue(EEWPresentation.showsDisclaimer(try XCTUnwrap(EEWPayload("1|1", provider: "trem"))))
        XCTAssertEqual(strings.disclaimer, "最終結果應以氣象署發布之內容為準")
    }

    // MARK: - Text

    func testReportNumbersAndPlaceholders() throws {
        func text(_ d: String) throws -> [String] {
            let payload = try XCTUnwrap(EEWPayload(d, provider: "trem"))
            return [
                strings.reportNumber(payload), strings.epicenter(payload), strings.magnitude(payload),
                strings.depth(payload), EEWStrings.originTime(payload.origin),
            ]
        }
        XCTAssertEqual(try text("1|3|0|1795888105|23.95|121.71|花蓮縣近海|5.8|20|4|4||0"),
                       ["#3", "花蓮縣近海", "M5.8", "20 km", "01:48:25"])
        XCTAssertEqual(try text("1|6|3|1795888105|23.85|121.62|x|7.1|15|4|8|2|0").first, "#6(最終)")
        XCTAssertEqual(try text("1|2|6|1795888105|||||||||0"), ["#2(取消)", "—", "M—", "— km", "01:48:25"])
        // No source parameters: the slots stay, the values become placeholders,
        // and the epicentre name sent alongside is ignored.
        XCTAssertEqual(try text("1|1|8|1795888105|23.99|121.60|花蓮縣|1.0|10|2|||3"),
                       ["#1", "無震源參數推定", "M—", "— km", "01:48:25"])
        XCTAssertEqual(try text("1"), ["#—", "—", "M—", "— km", "—"])
    }

    func testIntensityText() {
        XCTAssertEqual((0...9).map { strings.intensity($0) }, ["0級", "1級", "2級", "3級", "4級", "5弱", "5強", "6弱", "6強", "7級"])
        XCTAssertEqual(strings.intensity(nil), "—")
        XCTAssertEqual(
            (0...9).map { strings.compactIntensity($0) }, ["0", "1", "2", "3", "4", "5弱", "5強", "6弱", "6強", "7"])
        let english = Self.catalogStrings("en")
        XCTAssertEqual((0...9).map { english.intensity($0) }, ["0", "1", "2", "3", "4", "5−", "5+", "6−", "6+", "7"])
        XCTAssertEqual(english.spokenIntensity(5), "Level 5 weak")
        XCTAssertEqual(english.spokenIntensity(nil), "Not determined")
        XCTAssertTrue(EEWIntensityBlock.split("5弱") == ("", "5", "弱"))
        XCTAssertTrue(EEWIntensityBlock.split("Level 5") == ("Level ", "5", ""))
        XCTAssertTrue(EEWIntensityBlock.split("—") == ("", "—", ""))
    }

    // MARK: - Arrival

    /// 抵達 on the server's stale-date or once the widget's own arrival has
    /// passed; 未提供 without an epicentre or source parameters, stale or not;
    /// 取消 for a cancellation.
    func testArrival() throws {
        let estimate = EEWLocalShaking.Estimate(scale: 4, intensity: 4, sArrivalMs: 6581)
        let arrival = origin.addingTimeInterval(6.581)
        func slot(_ d: String, estimate: EEWLocalShaking.Estimate?, stale: Bool, at now: Date) throws
            -> EEWPresentation.Arrival {
            EEWPresentation.arrival(
                for: try XCTUnwrap(EEWPayload(d, provider: "trem")), estimate: estimate, isStale: stale, now: now)
        }
        let usable = "1|3|0|1795888105|23.95|121.71|花蓮縣近海|5.8|20|4|4||0"
        XCTAssertEqual(try slot(usable, estimate: estimate, stale: false, at: origin), .countdown(arrival))
        XCTAssertEqual(try slot(usable, estimate: estimate, stale: false, at: arrival.addingTimeInterval(-0.001)),
                       .countdown(arrival))
        XCTAssertEqual(try slot(usable, estimate: estimate, stale: false, at: arrival), .arrived)
        XCTAssertEqual(try slot(usable, estimate: estimate, stale: true, at: origin), .arrived)
        // No table or observer: nothing to count down to, but the server's
        // stale-date still means the wave has reached this township.
        XCTAssertEqual(try slot(usable, estimate: nil, stale: false, at: origin), .unavailable)
        XCTAssertEqual(try slot(usable, estimate: nil, stale: true, at: origin), .arrived)
        // No epicentre, or no source parameters: 未提供 whatever the stale-date.
        for d in ["1|3|0|1795888105|||x|5.8|20|4|4||0", "1|1|8|1795888105|23.99|121.60|花蓮縣|1.0|10|2|||3"] {
            XCTAssertEqual(try slot(d, estimate: estimate, stale: true, at: arrival), .unavailable, d)
        }
        XCTAssertEqual(try slot("1|2|4|1795888105|||||||||0", estimate: nil, stale: true, at: origin), .cancelled)
        XCTAssertEqual(strings.slot(.arrived), "抵達")
        XCTAssertEqual(strings.slot(.unavailable), "未提供")
        XCTAssertEqual(strings.slot(.cancelled), "取消")
        XCTAssertNil(strings.slot(.countdown(arrival)))
        XCTAssertEqual(strings.arrivalLabel(.arrived), "震波")
        XCTAssertEqual(strings.arrivalLabel(.countdown(arrival)), "震波預計抵達")
    }

    /// The safety net for a missed `end`: only a readable report long past
    /// its origin is ended.
    func testJanitorEndsOnlyLongPastReports() {
        let state = Runner.EEWActivityAttributes.ContentState(d: "1|3|0|1795888105|23.95|121.71|x|5.8|20|4|4||0")
        let lifetime = Runner.EEWLiveActivityJanitor.lifetime
        XCTAssertFalse(Runner.EEWLiveActivityJanitor.isExpired(state, provider: "trem", now: origin.addingTimeInterval(lifetime)))
        XCTAssertTrue(Runner.EEWLiveActivityJanitor.isExpired(state, provider: "trem", now: origin.addingTimeInterval(lifetime + 1)))
        XCTAssertFalse(Runner.EEWLiveActivityJanitor.isExpired(.init(d: "2|3|0|1"), provider: "trem", now: .distantFuture))
        XCTAssertFalse(Runner.EEWLiveActivityJanitor.isExpired(.init(d: "1|3|0|"), provider: "trem", now: .distantFuture))
    }

    // MARK: - Layout

    /// Every kind of report the layouts must hold, at its widest.
    private var layoutScenarios: [(String, String, Int?)] {
        [
            ("cwa", "1|2|0|1795888105|23.95|121.71|花蓮縣近海|6.6|10|5", 4),
            ("cwa", "1|123|3|1795888105|23.85|121.62|花蓮縣壽豐鄉近海|7.1|15|9", 9),
            ("trem", "1|3|0|1795888105|23.95|121.71|花蓮縣近海|5.8|20|4|4||0", 4),
            ("trem", "1|1|0|1795888105|23.95|121.71|花蓮縣近海|4.6|10|1|||0", 3),
            ("trem", "1|1|8|1795888105|23.99|121.60|花蓮縣|1.0|10|2|||3", nil),
            ("trem", "1|3|9|1795888105|22.78|121.38|臺東縣近海|6.2|20|4|4|2|5", 3),
            ("trem", "1|6|3|1795888105|23.85|121.62|花蓮縣壽豐鄉近海|7.1|15|4|8|2|0", 7),
            ("trem", "1|2|4|1795888105|||||||||0", nil),
            ("trem", "1|123|11|1795888105|23.85|121.62|\(String(repeating: "花蓮縣壽豐鄉東南方外海", count: 3))|7.1|120|4|9|2|9", 9),
        ]
    }

    private func reports(_ strings: EEWStrings, stale: Bool) throws -> [EEWActivityReport] {
        try layoutScenarios.map { provider, d, scale in
            let payload = try XCTUnwrap(EEWPayload(d, provider: provider))
            let estimate = scale.map { EEWLocalShaking.Estimate(scale: $0, intensity: Double($0), sArrivalMs: 600_000) }
            return EEWActivityReport(payload: payload, estimate: estimate, isStale: stale, now: origin, strings: strings)
        }
    }

    /// iOS cuts a Lock Screen Live Activity off at 160 pt. Every scenario, in
    /// every language, at the narrowest and widest phones.
    @MainActor
    func testLockScreenStaysWithinTheSystemHeight() throws {
        for language in ["zh-Hant", "en", "ja", "ko", "zh-Hans"] {
            for stale in [false, true] {
                for report in try reports(Self.catalogStrings(language), stale: stale) {
                    for width in [320.0, 375, 430] {
                        let size = measured(EEWLockScreenView(report: report), width: width)
                        XCTAssertLessThanOrEqual(size.height, 160, "\(language) \(report.payload) width=\(width)")
                        XCTAssertLessThanOrEqual(size.width, width + 0.5, "\(language) width=\(width)")
                    }
                }
            }
        }
    }

    /// A TREM card keeps its note line even without a note, so the disclaimer
    /// never moves; a CWA card has neither line.
    @MainActor
    func testTremCardHeightDoesNotDependOnTheNote() throws {
        func report(_ provider: String, _ d: String) throws -> EEWActivityReport {
            EEWActivityReport(
                payload: try XCTUnwrap(EEWPayload(d, provider: provider)), estimate: nil, isStale: false, now: origin,
                strings: strings)
        }
        let withNote = try report("trem", "1|1|0|1795888105|23.95|121.71|x|4.6|10|1|||0")
        let withoutNote = try report("trem", "1|3|0|1795888105|23.95|121.71|x|5.8|20|4|4||0")
        XCTAssertNotNil(withNote.noteText)
        XCTAssertNil(withoutNote.noteText)
        XCTAssertEqual(
            measured(EEWLockScreenView(report: withNote), width: 375).height,
            measured(EEWLockScreenView(report: withoutNote), width: 375).height, accuracy: 0.5)
        let cwa = try report("cwa", "1|3|0|1795888105|23.95|121.71|x|5.8|20|4")
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
}
