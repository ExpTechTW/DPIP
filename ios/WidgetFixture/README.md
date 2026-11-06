# Widget fixture UI tests

Run the existing fixture and XCUITest scheme on an iOS simulator:

```sh
DPIP_IOS_SIMULATOR=<UDID> tool/dev/test_widget_ui.sh \
  -parallel-testing-enabled NO \
  -derivedDataPath /tmp/dpip-widget-ui-build \
  -resultBundlePath /tmp/dpip-widget-ui.xcresult
```

Use fresh build and result paths for each recorded run. Use
`-only-testing:WidgetFixtureUITests/MediumWeatherUITests/<test>` for a focused
case. No accessibility settings need to be enabled before running XCUITest.

The fixture compiles the production Medium weather view and its String
Catalog directly. Neither fixture target is embedded in Runner or its widget
extension. Set these environment variables on the fixture process (the UI
tests use `XCUIApplication.launchEnvironment`):

| Variable | Values (default first) |
| --- | --- |
| `DPIP_FIXTURE_FORECAST` | `stale`, `fresh`, `expired`, `unavailable` |
| `DPIP_FIXTURE_LANGUAGE` | `en`, `zh-Hant`, `zh-Hans`, `ja`, `ko` |
| `DPIP_FIXTURE_TEXT_SIZE` | `normal` (.large), `larger` (.xLarge), `accessibility` (.accessibility1) |
| `DPIP_FIXTURE_LOCATION` | `short` (Taichung Xitun), `compact` (Xitun), `long` (Taichung City Xitun District Shuinan Central Park) |

The fixture uses a fixed September 25, 2026 entry (15:21 in Asia/Taipei) and
a distinct observation time (14:21). Fresh, stale and expired forecasts use
the same points with publication ages of 15, 45 and 135 minutes respectively;
unavailable supplies no forecast. All four keep the current observation.
The selected localization bundle and SwiftUI Locale drive the widget strings
and time formatting. The system UI language is not switched.

| Forecast | Widget language | Size / location | Warning role | Refresh |
| --- | --- | --- | --- | --- |
| Stale | en | normal / short | Image | Button |
| Stale | en | normal / compact | StaticText | Button |
| Stale | zh-Hant, zh-Hans | normal / short | StaticText | Button |
| Stale | ja, ko | normal / short | Image | Button |
| Stale | en | larger / long | Image | Button |
| Stale | en | accessibility / long | Image | Button |
| Fresh | en | normal / short | Absent | Absent |
| Expired, unavailable | en | normal / short | Absent | Button |

The card has a fixed 338 × 158 pt presentation and 16 pt margins. An
independent sibling element reports the card frame in screen coordinates
without collecting the widget descendants' frames. The assertions check
accessibility labels and geometry, including a 44 × 44 pt refresh button and
representative forecast time, temperature and precipitation. They do not
invoke the refresh intent, measure rendered glyphs or exercise WidgetKit or
VoiceOver. The normal and .xLarge captures clip the bottom precipitation
glyphs, as in Phase 1. The test checks semantic placement with a frame that
intersects the forecast region. The .accessibility1 capture shows a single
forecast row inside the card; both long-location cases visually abbreviate
the location but keep its full accessibility label. An .xxxLarge pilot
placed precipitation entirely below the card and the temperature frame
partly outside it. Named screenshots remain attached to the result bundle.

Phase 2A checked two temporary fixture-only mutations on the English stale
case: supplying the entry date as the observation date made the expected
observation count zero; rendering a second warning with the same catalog
label made the warning count two. The fixture was restored after each run.

Phase 2A keeps both app-hosted Medium XCTest cases intact. Before replacing
them, compare coverage against their full locale, text-size and forecast
matrix. Phase 1's observation-removed, warning-removed and out-of-bounds
controls remain in the original PoC evidence (`remove-time`,
`remove-warning-real` and `move-time-bounded` logs and result bundles).
