import SwiftUI
import Testing
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
                XCTAssertEqual(
                    EEWPresentation.intensityLabel(for: state),
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
                XCTAssertEqual(
                    EEWPresentation.intensityText(ordinal, compact: compact),
                    .init(key: "eew.intensity." + key, level: nil))
                XCTAssertEqual(
                    EEWPresentation.intensityText(ordinal, compact: compact, spoken: true),
                    .init(key: "eew.intensity." + key + ".spoken", level: nil))
            }
        }
        for (ordinal, level) in [(1, 1), (2, 2), (3, 3), (4, 4), (9, 7)] {
            XCTAssertEqual(EEWPresentation.intensityText(ordinal), .init(key: "eew.intensity.format", level: level))
            XCTAssertEqual(
                EEWPresentation.intensityText(ordinal, compact: true),
                .init(key: "eew.intensity.compact.format", level: level))
            XCTAssertEqual(
                EEWPresentation.intensityText(ordinal, compact: true, spoken: true),
                .init(key: "eew.intensity.format", level: level))
        }
    }

    func testReportDetailsDoNotChangePrimaryStateSelection() {
        let state = state(
            local: 8, eta: epoch, report: 123,
            epicenter: "Long epicenter used only as synthetic layout stress data")
        XCTAssertEqual(state.reportNo, 123)
        XCTAssertEqual(EEWPresentation.intensity(for: state), 8)
        XCTAssertEqual(EEWPresentation.arrival(for: state), .countdown(epoch))
    }

    func testIslandFallbackPreservesArrivalSemantics() {
        for local in [nil, 4, 5, 8] as [Int?] {
            XCTAssertEqual(EEWPresentation.islandArrivalSymbol(for: state(local: local, eta: epoch)), "clock")
            XCTAssertEqual(
                EEWPresentation.islandArrivalSymbol(for: state(local: local, eta: nil)),
                "clock.badge.questionmark")
            for eta in [nil, epoch] as [Date?] {
                XCTAssertEqual(
                    EEWPresentation.islandArrivalSymbol(for: state(local: local, eta: eta, arrived: true)),
                    "checkmark")
            }
        }
    }

    func testTimerEnvelopeReservesRemainingDigitsAcrossETABoundary() {
        for (seconds, sample, afterOneSecond) in [
            (0.0, "8:88", "8:88"), (9, "8:88", "8:88"), (18, "8:88", "8:88"),
            (59, "8:88", "8:88"), (60, "8:88", "8:88"), (120, "8:88", "8:88"),
            (35, "8:88", "8:88"), (125, "8:88", "8:88"),
            (599.9, "88:88", "8:88"), (599.1, "88:88", "8:88"),
            (599, "8:88", "8:88"), (600, "88:88", "8:88"), (6_000, "888:88", "88:88"),
            (5_999.9, "888:88", "88:88"),
        ] {
            let state = state(local: nil, eta: epoch.addingTimeInterval(seconds))
            for (elapsed, expected) in [(0.0, sample), (1.0, afterOneSecond), (seconds + 1, "8:88")] {
                XCTAssertEqual(
                    EEWPresentation.islandTimerSample(for: state, now: epoch.addingTimeInterval(elapsed)),
                    expected)
                XCTAssertEqual(EEWPresentation.arrival(for: state), .countdown(epoch.addingTimeInterval(seconds)))
            }
        }
        XCTAssertEqual(EEWPresentation.islandTimerSample(for: state(local: nil, eta: nil), now: epoch), "8:88")
    }

    func testBadgePaletteAndSmallTextContrast() {
        // Pin the published DPIP palette, including every CWA weak/strong ordinal.
        let expected = [
            0x9E9E9E, 0x003264, 0x0064C8, 0x1E9632, 0xFFC800,
            0xFF9600, 0xFF6400, 0xFF0000, 0xC00000, 0x9600C8,
        ]
        for (ordinal, rgb) in expected.enumerated() {
            let background = components(EEWIntensityColor.color(for: ordinal))
            XCTAssertEqual(background[0], Double((rgb >> 16) & 255) / 255, accuracy: 0.001)
            XCTAssertEqual(background[1], Double((rgb >> 8) & 255) / 255, accuracy: 0.001)
            XCTAssertEqual(background[2], Double(rgb & 255) / 255, accuracy: 0.001)
            XCTAssertEqual(background[3], 1, accuracy: 0.001)
            let foreground = components(EEWIntensityColor.foreground(for: ordinal))
            let luminances = [luminance(background), luminance(foreground)].sorted()
            let contrast = (luminances[1] + 0.05) / (luminances[0] + 0.05)
            XCTAssertGreaterThanOrEqual(contrast, 4.5, "Small badge text: ordinal \(ordinal)")
        }
        for unknown in [-1, 10] {
            XCTAssertEqual(
                components(EEWIntensityColor.color(for: unknown)),
                components(EEWIntensityColor.color(for: 0)))
        }
    }

    func testEveryIntensityKeepsLocalAndMaximumFallbackSemantics() {
        for ordinal in 0...9 {
            for local in [nil, ordinal] as [Int?] {
                for eta in [nil, epoch] as [Date?] {
                    let state = EEWActivityAttributes.ContentState(
                        reportNo: 1, originAt: epoch, magnitude: 6, depthKm: 20,
                        epicenter: "Synthetic epicenter", reportMaxIntensity: ordinal,
                        estimatedLocalIntensity: local, estimatedSArrivalAt: eta, waveArrived: false
                    )
                    XCTAssertEqual(EEWPresentation.intensity(for: state), ordinal)
                    XCTAssertEqual(
                        EEWPresentation.intensityLabel(for: state),
                        local == nil ? "eew.intensity.max" : "eew.intensity.local"
                    )
                    XCTAssertEqual(EEWPresentation.arrival(for: state), eta.map { .countdown($0) } ?? .unavailable)
                }
            }
        }
    }

    @MainActor
    func testLargeTypeStillDegradesWithoutOverflow() {
        for size in [DynamicTypeSize.xxxLarge, .accessibility3] {
            for limited in [false, true] {
                let content = EEWIslandIntensityPresentation(intensity: 8, limitedInWidth: limited) {
                    Text(verbatim: "6強")
                } testBadge: {
                    Text(verbatim: "TEST").font(.system(size: 8, weight: .bold))
                }
                .font(.caption.bold())
                .dynamicTypeSize(size)
                for width in [4.0, 12, 24, 32, 40, 60, 100] {
                    let measuredSize = measured(content, width: width)
                    XCTAssertLessThanOrEqual(measuredSize.width, width + 0.5)
                    XCTAssertLessThanOrEqual(measuredSize.height, 36.5)
                }
            }
        }
    }

    @MainActor
    func testBadgeCandidatesKeepWholeClassificationsAtEveryWidth() {
        for (ordinal, label) in [
            (1, "1"), (2, "2"), (3, "3"), (4, "4"),
            (5, "5弱"), (6, "5強"), (7, "6弱"), (8, "6強"), (9, "7"),
            (5, "5−"), (6, "5+"), (7, "6−"), (8, "6+"),
        ] {
            for limited in [false, true] {
                let content = EEWIslandIntensityPresentation(intensity: ordinal, limitedInWidth: limited) {
                    Text(verbatim: label)
                } testBadge: {
                    Text(verbatim: "TEST").font(.system(size: 8, weight: .bold))
                }
                .font(.caption.bold())
                let badge = EEWIslandIntensityBadge(intensity: ordinal) { Text(verbatim: label) }
                let dense = EEWIslandIntensityBadge(intensity: ordinal, dense: true) { Text(verbatim: label) }
                let badgeSize = measured(badge, width: 200)
                let denseSize = measured(dense, width: 200)
                XCTAssertLessThan(denseSize.width, badgeSize.width)
                XCTAssertLessThan(denseSize.height, badgeSize.height)
                let normal = measured(content, width: 200)
                if limited {
                    XCTAssertEqual(normal.width, badgeSize.width, accuracy: 0.5)
                } else {
                    XCTAssertGreaterThan(normal.width, badgeSize.width)
                    // TEST may disappear while waveform + full badge still fit.
                    let withoutTest = measured(content, width: normal.width - 1)
                    XCTAssertGreaterThan(withoutTest.width, badgeSize.width)
                    XCTAssertLessThan(withoutTest.width, normal.width)
                }
                let narrow = measured(content, width: denseSize.width + 0.5)
                XCTAssertEqual(narrow.width, denseSize.width, accuracy: 0.5)
                let textWidth = measured(
                    Text(verbatim: label).font(.caption2.bold()).monospacedDigit(), width: 200
                ).width
                if textWidth < denseSize.width - 0.5 {
                    XCTAssertEqual(measured(content, width: textWidth + 0.25).width, textWidth, accuracy: 0.5)
                }
                for width in [4.0, 8, 12, 16, 24, 32, 40, 60, 100] {
                    let size = measured(content, width: width)
                    XCTAssertLessThanOrEqual(size.width, width + 0.5, "\(label), limited=\(limited)")
                    XCTAssertLessThanOrEqual(size.height, 36.5)
                }
            }
        }
    }

    @MainActor
    func testTimerEnvelopeCentersItsOverlayWithoutChangingDigitProtection() throws {
        // Pixel measurement of the shared overlay region, not a claim about
        // ActivityKit's autonomous timer or the system-managed Island position.
        for sample in ["8:88", "88:88", "888:88"] {
            let content = EEWIslandTimerEnvelope(sample: sample) {
                Color.white.frame(width: 6, height: 4)
            }
            .font(.caption.bold())
            let renderer = ImageRenderer(content: content)
            renderer.scale = 3
            let image = try XCTUnwrap(renderer.cgImage)
            let bytes = try XCTUnwrap(image.dataProvider?.data)
            let data = try XCTUnwrap(CFDataGetBytePtr(bytes))
            var columns: [Int] = []
            for x in 0..<image.width {
                for y in 0..<image.height {
                    let offset = y * image.bytesPerRow + x * (image.bitsPerPixel / 8)
                    if data[offset + 3] > 128 {
                        columns.append(x)
                        break
                    }
                }
            }
            let left = try XCTUnwrap(columns.min())
            let right = try XCTUnwrap(columns.max())
            XCTAssertEqual(Double(left + right) / 2, Double(image.width - 1) / 2, accuracy: 1)
        }
    }

    private func components(_ color: Color) -> [Double] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return [red, green, blue, alpha].map(Double.init)
    }

    private func luminance(_ components: [Double]) -> Double {
        let linear = components.prefix(3).map { value in
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    }

    @MainActor
    func testFittingMeasuresWholeIntensityInsteadOfAcceptingTruncatedText() {
        // Real SwiftUI text measurement, not character-count width estimates.
        // The same fitting container is used by both compact Island regions.
        for (fullLabel, label) in [
            ("5弱", "5弱"), ("6強", "6強"), ("5−", "5−"),
            ("6+", "6+"), ("7級", "7"), ("4級", "4"),
        ] {
            for limited in [false, true] {
                let content = EEWIslandFittingView(limitedInWidth: limited) {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                        Text(verbatim: fullLabel)
                        Text(verbatim: "TEST")
                    }
                } compact: {
                    Text(verbatim: label)
                } fallback: {
                    Color.red.frame(width: 4, height: 4)
                }
                .font(.caption.bold())
                let labelWidth = measured(Text(verbatim: label).font(.caption.bold()), width: 200).width
                let normal = measured(content, width: 200)
                XCTAssertGreaterThanOrEqual(normal.width, labelWidth)
                if limited { XCTAssertEqual(normal.width, labelWidth, accuracy: 0.5) }
                let abbreviated = measured(content, width: labelWidth + 1)
                XCTAssertEqual(abbreviated.width, labelWidth, accuracy: 0.5)
                let tooNarrow = measured(content, width: labelWidth - 1)
                XCTAssertEqual(
                    tooNarrow.width, 4, accuracy: 0.5,
                    "A partial intensity must never win: \(label), limited=\(limited)")
                XCTAssertLessThanOrEqual(tooNarrow.height, 20)
            }
        }
    }

    @MainActor
    func testTerminalSymbolsRespectTinyProposedWidths() {
        for symbol in ["waveform.path.ecg", "clock", "clock.badge.questionmark", "checkmark"] {
            let content = EEWIslandFittingView(limitedInWidth: false) {
                Text(verbatim: "Full candidate")
            } compact: {
                Text(verbatim: "5弱")
            } fallback: {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 14, maxHeight: 14)
            }
            for width in [4.0, 8, 12] {
                let size = measured(content, width: width)
                XCTAssertLessThanOrEqual(size.width, width + 0.5)
                XCTAssertLessThanOrEqual(size.height, 14.5)
            }
        }
    }

    @MainActor
    func testMinimalKeepsTimerEnvelopeWhenItFitsEvenWithLimitedWidthHint() {
        for sample in ["8:88", "88:88", "888:88"] {
            for limited in [false, true] {
                let envelope = EEWIslandTimerEnvelope(sample: sample) {
                    // A greedy overlay models timer Text's layout behavior. The
                    // real timer's autonomous rendering still needs system QA.
                    Color.green
                }
                .font(.caption2.bold())
                let width = measured(envelope, width: 200).width
                let content = EEWIslandFittingView(limitedInWidth: limited) {
                    envelope
                } compact: {
                    envelope
                } fallback: {
                    Color.red.frame(width: 8, height: 8)
                }
                XCTAssertEqual(measured(content, width: width + 1).width, width, accuracy: 0.5)
                XCTAssertEqual(measured(content, width: width - 1).width, 8, accuracy: 0.5)
            }
        }
    }

    @MainActor
    func testWidthReaderHasWorkingCompatibleContent() {
        let content = EEWIslandWidthReader { _ in Text(verbatim: "EEW") }
        XCTAssertGreaterThan(measured(content, width: 200).width, 0)
    }

    @MainActor
    func testWidthReaderUsesCompatibleFittingPath() {
        // Every SDK uses false; narrow proposals still select smaller candidates
        // through ViewThatFits, as exercised by the fitting tests above.
        let content = EEWIslandWidthReader { limited in
            Color.red.frame(width: limited ? 8 : 40, height: 8)
        }
        XCTAssertEqual(measured(content, width: 100).width, 40, accuracy: 0.5)
    }

    @MainActor
    private func measured<Content: View>(_ content: Content, width: CGFloat) -> CGSize {
        autoreleasepool {
            let host = UIHostingController(rootView: content)
            return host.sizeThatFits(in: CGSize(width: width, height: 36))
        }
    }

    private func state(
        local: Int?, eta: Date?, arrived: Bool = false,
        report: Int = 4, epicenter: String = "Synthetic epicenter"
    ) -> EEWActivityAttributes.ContentState {
        .init(
            reportNo: report, originAt: epoch, magnitude: 6.1, depthKm: 20,
            epicenter: epicenter, reportMaxIntensity: 5, estimatedLocalIntensity: local,
            estimatedSArrivalAt: eta, waveArrived: arrived)
    }
}

@MainActor
struct EEWCountdownInkTests {
    @Test
    func completeSystemTimerFitsItsMeasuredEnvelope() throws {
        guard #available(iOS 16.1, *) else { return }
        // Pause only this rendering fixture, so both images contain the same
        // real timer glyphs. ImageRenderer does not prove background ticking or
        // SpringBoard's multi-activity mask; those require separate manual QA.
        // Keep the interval in the future instead of racing the rendering
        // host's current clock. Pin both integral and fractional timestamps;
        // the explicit m:ss reference below also proves the fixture is paused
        // at the intended duration rather than silently rendering zero.
        for fraction in [0.0, 0.1, 0.5, 0.9] {
            let now = Date(timeIntervalSince1970: 5_000_000_000 + fraction)
            for seconds in [600.0, 599.9, 599.1, 599, 120, 60, 59, 18, 9, 0] {
                let arrival = now.addingTimeInterval(seconds)
                let state = EEWActivityAttributes.ContentState(
                    reportNo: 1, originAt: now, magnitude: 6, depthKm: 20,
                    epicenter: "Synthetic epicenter", reportMaxIntensity: 5,
                    estimatedLocalIntensity: 4, estimatedSArrivalAt: arrival, waveArrived: false)
                let timer = Text(timerInterval: now...arrival, pauseTime: now, countsDown: true, showsHours: false)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                for font in [Font.caption.bold(), .caption2.bold()] {
                    for locale in [Locale(identifier: "zh_TW"), Locale(identifier: "en_US")] {
                        let envelope = EEWIslandTimerEnvelope(
                            sample: EEWPresentation.islandTimerSample(for: state, now: now)
                        ) { timer }
                            .font(font)
                            .environment(\.locale, locale)
                            .fixedSize()
                        let reference = timer.font(font)
                            .environment(\.locale, locale)
                            .frame(width: 200)
                        let actual = try inkBounds(envelope)
                        let complete = try inkBounds(reference)
                        let remaining = Int(ceil(seconds))
                        let expectedText = String(format: "%d:%02d", remaining / 60, remaining % 60)
                        let expected = try inkBounds(
                            Text(verbatim: expectedText).monospacedDigit().foregroundStyle(.white)
                                .font(font).environment(\.locale, locale).frame(width: 200))
                        #expect(
                            abs(complete.inkWidth - expected.inkWidth) <= 2,
                            "Paused timer must show \(expectedText), fraction=\(fraction), locale=\(locale.identifier)")
                        #expect(
                            abs(actual.inkWidth - complete.inkWidth) <= 2,
                            "seconds=\(seconds), fraction=\(fraction), font=\(font), locale=\(locale.identifier), actual=\(actual), complete=\(complete)")
                        #expect(actual.left >= 3)
                        #expect(actual.right < actual.imageWidth - 3)
                        #expect(abs(actual.left + actual.right - (actual.imageWidth - 1)) <= 4)
                    }
                }
            }
        }
    }

    @available(iOS 16.0, *)
    private func inkBounds<Content: View>(_ content: Content) throws -> (
        left: Int, right: Int, inkWidth: Int, imageWidth: Int
    ) {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        let image = try #require(renderer.cgImage)
        let bytes = try #require(image.dataProvider?.data)
        let data = try #require(CFDataGetBytePtr(bytes))
        var columns: [Int] = []
        for x in 0..<image.width {
            for y in 0..<image.height {
                let offset = y * image.bytesPerRow + x * (image.bitsPerPixel / 8)
                if data[offset + 3] > 128 {
                    columns.append(x)
                    break
                }
            }
        }
        let left = try #require(columns.min())
        let right = try #require(columns.max())
        return (left, right, right - left + 1, image.width)
    }
}
