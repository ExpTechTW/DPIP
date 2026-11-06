import XCTest

final class MediumWeatherUITests: XCTestCase {
    func testEnglishStaleMediumHeader() {
        let app = XCUIApplication()
        app.launch()
        let location = app.staticTexts["Taichung Xitun"]
        XCTAssertTrue(location.waitForExistence(timeout: 10))

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "medium-stale-english"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        print("ACCESSIBILITY HIERARCHY\n\(app.debugDescription)")

        let time = app.staticTexts.matching(NSPredicate(format: "label == %@", "2:21\u{202F}PM"))
        let warnings = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@ AND (elementType == %d OR elementType == %d)",
                        "Forecast may be outdated", XCUIElement.ElementType.staticText.rawValue,
                        XCUIElement.ElementType.image.rawValue)
        )
        let refresh = app.buttons.matching(NSPredicate(format: "label == %@", "Refresh forecast"))
        XCTAssertEqual(time.count, 1)
        XCTAssertEqual(warnings.count, 1)
        XCTAssertEqual(refresh.count, 1)
        guard time.count == 1, warnings.count == 1, refresh.count == 1 else { return }
        XCTAssertEqual(time.element.label, "2:21\u{202F}PM")
        XCTAssertEqual(warnings.element.label, "Forecast may be outdated")
        XCTAssertEqual(refresh.element.label, "Refresh forecast")
        XCTAssertEqual(refresh.element.frame.width, 44, accuracy: 0.5)
        XCTAssertEqual(refresh.element.frame.height, 44, accuracy: 0.5)

        // The card's semantic frame can expand beyond its clipped presentation.
        // Anchor fixed bounds to the known 16-point inset, not the AX card size.
        let card = app.otherElements["widget-card"]
        XCTAssertTrue(card.exists)
        let bounds = CGRect(origin: card.frame.origin, size: CGSize(width: 338, height: 158))
        let timeFrame = time.element.frame
        let warningFrame = warnings.element.frame
        print("PRESENTATION bounds=\(bounds) time=\(timeFrame) warning=\(warningFrame) refresh=\(refresh.element.frame)")
        XCTAssertTrue(bounds.contains(timeFrame), "Observation time outside fixed presentation")
        XCTAssertTrue(bounds.contains(warningFrame), "Warning outside fixed presentation")
        XCTAssertLessThan(warningFrame.maxX, timeFrame.minX)
    }
}
