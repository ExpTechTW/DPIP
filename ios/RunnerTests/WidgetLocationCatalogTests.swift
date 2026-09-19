import XCTest
@testable import Runner

final class WidgetLocationCatalogTests: XCTestCase {
    func testDecodesSchemaVersionOneCatalog() throws {
        let json = """
        {
          "schemaVersion": 1,
          "locations": [
            {
              "regionCode": "220",
              "displayName": "板橋區",
              "administrativeAreaName": "新北市",
              "latitude": 25.0096156,
              "longitude": 121.4592358
            }
          ]
        }
        """

        let catalog = WidgetLocationCatalogStore.decode(
            Data(json.utf8)
        )

        XCTAssertNotNil(catalog)
        XCTAssertEqual(catalog?.schemaVersion, 1)
        XCTAssertEqual(catalog?.locations.count, 1)
        XCTAssertEqual(catalog?.locations[0].regionCode, "220")
        XCTAssertEqual(catalog?.locations[0].displayName, "板橋區")
        XCTAssertEqual(
            catalog?.locations[0].administrativeAreaName,
            "新北市"
        )
    }

    func testRejectsUnsupportedSchemaVersion() {
        let json = """
        {
          "schemaVersion": 2,
          "locations": []
        }
        """

        XCTAssertNil(
            WidgetLocationCatalogStore.decode(
                Data(json.utf8)
            )
        )
    }

    func testRejectsMalformedCatalog() {
        let json = """
        {
          "schemaVersion": 1,
          "locations": [
            {
              "regionCode": "220"
            }
          ]
        }
        """

        XCTAssertNil(
            WidgetLocationCatalogStore.decode(
                Data(json.utf8)
            )
        )
    }
}
